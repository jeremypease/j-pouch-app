#!/bin/bash
#
# Creates the App Store distribution certificate and provisioning profile via the App Store
# Connect API, then installs both locally.
#
# Needed because cloud signing — where xcodebuild asks Apple to mint these on demand — returns
# "Cloud signing permission error" on this account, even with an App Manager key that can
# demonstrably read certificates, profiles and bundle IDs, and with no agreements outstanding.
# Creating them explicitly sidesteps whatever cloud signing is unhappy about.
#
# Run once. Certificates last a year; the profile is renewable by re-running.
#
#   export ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_PATH=...
#   ./Scripts/create-signing-assets.sh

set -euo pipefail
cd "$(dirname "$0")/.."

if [ -f .release-env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.release-env
    set +a
fi

: "${ASC_KEY_ID:?Set ASC_KEY_ID, or put it in .release-env}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID}"
: "${ASC_KEY_PATH:?Set ASC_KEY_PATH}"

KEY_PATH=${ASC_KEY_PATH/#\~/$HOME}
export API_PRIVATE_KEYS_DIR="$(cd "$(dirname "$KEY_PATH")" && pwd)"

BUNDLE_ID="com.jeremypease.jpouch"
PROFILE_NAME="JPouch App Store"
# Kept outside the repo: this private key is what actually signs the app.
SIGNING_DIR="$HOME/private_keys/jpouch-signing"
mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

JWT=$(xcrun altool --generate-jwt --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -1)
[ ${#JWT} -gt 50 ] || { echo "Could not generate a JWT: $JWT" >&2; exit 1; }
API="https://api.appstoreconnect.apple.com/v1"
auth=(-H "Authorization: Bearer $JWT" -H "Content-Type: application/json")

fail_on_error() {
    python3 -c "
import json,sys
raw=sys.stdin.read()
try: r=json.loads(raw)
except Exception: print(raw); sys.exit(1)
if 'errors' in r:
    for e in r['errors']:
        print('API error:', e.get('title'), '-', e.get('detail'), file=sys.stderr)
    sys.exit(1)
print(json.dumps(r))
"
}

# --- Distribution certificate -------------------------------------------------

CERT_ID=$(curl -s "${auth[@]}" "$API/certificates?limit=200" | python3 -c "
import json,sys
for c in json.load(sys.stdin).get('data',[]):
    if c['attributes'].get('certificateType')=='DISTRIBUTION':
        print(c['id']); break
")

if [ -n "$CERT_ID" ]; then
    echo "==> Reusing existing distribution certificate $CERT_ID"
    curl -s "${auth[@]}" "$API/certificates/$CERT_ID" | python3 -c "
import json,sys,base64
c=json.load(sys.stdin)['data']['attributes']
open('$SIGNING_DIR/distribution.cer','wb').write(base64.b64decode(c['certificateContent']))
"
else
    echo "==> Generating private key and CSR"
    if [ ! -f "$SIGNING_DIR/distribution.key" ]; then
        openssl genrsa -out "$SIGNING_DIR/distribution.key" 2048 2>/dev/null
        chmod 600 "$SIGNING_DIR/distribution.key"
    fi
    openssl req -new -key "$SIGNING_DIR/distribution.key" -out "$SIGNING_DIR/distribution.csr" \
        -subj "/emailAddress=jeremypease@me.com/CN=J-Pouch Distribution/C=US" 2>/dev/null

    CSR_JSON=$(python3 -c "
import json
print(json.dumps(open('$SIGNING_DIR/distribution.csr').read()))
")

    echo "==> Requesting distribution certificate"
    RESPONSE=$(curl -s "${auth[@]}" -X POST "$API/certificates" -d "{
      \"data\": {
        \"type\": \"certificates\",
        \"attributes\": {
          \"certificateType\": \"DISTRIBUTION\",
          \"csrContent\": $CSR_JSON
        }
      }
    }")
    echo "$RESPONSE" | fail_on_error > /dev/null
    echo "$RESPONSE" | python3 -c "
import json,sys,base64
d=json.load(sys.stdin)['data']
open('$SIGNING_DIR/distribution.cer','wb').write(base64.b64decode(d['attributes']['certificateContent']))
print('   created certificate', d['id'])
"
    CERT_ID=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['id'])")
fi

echo "==> Installing certificate into the login keychain"
# The .cer from Apple is only the public half; pairing it with the private key we generated
# produces the identity codesign needs.
openssl x509 -inform DER -in "$SIGNING_DIR/distribution.cer" -out "$SIGNING_DIR/distribution.pem" 2>/dev/null
if [ -f "$SIGNING_DIR/distribution.key" ]; then
    openssl pkcs12 -export -legacy \
        -inkey "$SIGNING_DIR/distribution.key" \
        -in "$SIGNING_DIR/distribution.pem" \
        -out "$SIGNING_DIR/distribution.p12" \
        -passout pass:jpouch 2>/dev/null || \
    openssl pkcs12 -export \
        -inkey "$SIGNING_DIR/distribution.key" \
        -in "$SIGNING_DIR/distribution.pem" \
        -out "$SIGNING_DIR/distribution.p12" \
        -passout pass:jpouch 2>/dev/null
    security import "$SIGNING_DIR/distribution.p12" -k ~/Library/Keychains/login.keychain-db \
        -P jpouch -T /usr/bin/codesign -T /usr/bin/security 2>&1 | grep -v "already exists" || true
else
    security import "$SIGNING_DIR/distribution.pem" -k ~/Library/Keychains/login.keychain-db \
        -T /usr/bin/codesign 2>&1 | grep -v "already exists" || true
fi

# --- Provisioning profile -----------------------------------------------------

BUNDLE_RECORD=$(curl -s "${auth[@]}" "$API/bundleIds?filter%5Bidentifier%5D=$BUNDLE_ID" \
  | python3 -c "import json,sys; d=json.load(sys.stdin).get('data',[]); print(d[0]['id'] if d else '')")
[ -n "$BUNDLE_RECORD" ] || { echo "No bundle ID record for $BUNDLE_ID" >&2; exit 1; }

EXISTING_PROFILE=$(curl -s "${auth[@]}" "$API/profiles?limit=200" | python3 -c "
import json,sys
for p in json.load(sys.stdin).get('data',[]):
    a=p['attributes']
    if a.get('name')=='$PROFILE_NAME': print(p['id']); break
")
if [ -n "$EXISTING_PROFILE" ]; then
    echo "==> Removing previous '$PROFILE_NAME' so it can be reissued against the current certificate"
    curl -s "${auth[@]}" -X DELETE "$API/profiles/$EXISTING_PROFILE" >/dev/null
fi

echo "==> Creating App Store provisioning profile"
PROFILE_RESPONSE=$(curl -s "${auth[@]}" -X POST "$API/profiles" -d "{
  \"data\": {
    \"type\": \"profiles\",
    \"attributes\": {
      \"name\": \"$PROFILE_NAME\",
      \"profileType\": \"IOS_APP_STORE\"
    },
    \"relationships\": {
      \"bundleId\": { \"data\": { \"id\": \"$BUNDLE_RECORD\", \"type\": \"bundleIds\" } },
      \"certificates\": { \"data\": [ { \"id\": \"$CERT_ID\", \"type\": \"certificates\" } ] }
    }
  }
}")
echo "$PROFILE_RESPONSE" | fail_on_error > /dev/null

PROFILE_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"
echo "$PROFILE_RESPONSE" | python3 -c "
import json,sys,base64
d=json.load(sys.stdin)['data']
uuid=d['attributes']['uuid']
open('$PROFILE_DIR/'+uuid+'.mobileprovision','wb').write(base64.b64decode(d['attributes']['profileContent']))
print('   installed profile', d['attributes']['name'], uuid)
"

echo
echo "Done. Signing identities now available:"
security find-identity -v -p codesigning | grep -i distribution || echo "  (none found — check the import step above)"
