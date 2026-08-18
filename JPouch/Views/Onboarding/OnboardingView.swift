import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum Step: Int, CaseIterable {
        case welcome, track, privacy, stage, health, reminders

        /// The design opens with three slides before it asks anything — this is what the five
        /// page dots in the mockup were counting (three slides, stage, Health), not a screen
        /// missing from the app. Reminders is ours, added on top.
        var slide: (title: String, body: String, symbol: String?)? {
            switch self {
            case .welcome:
                return (
                    "Welcome to J-Pouch",
                    "Your companion for j-pouch surgery, recovery, and life after — one place to track how you're doing.",
                    nil
                )
            case .track:
                return (
                    "Track what matters",
                    "Output, hydration, medications, and symptoms — logged in seconds, so you can spot patterns instead of guessing.",
                    "chart.xyaxis.line"
                )
            case .privacy:
                return (
                    "Private, and yours",
                    "Your data stays with you. Share a summary with your care team only when you choose to.",
                    "lock.shield.fill"
                )
            case .stage, .health, .reminders:
                return nil
            }
        }
    }

    @State private var step: Step = .welcome

    // Stage
    @State private var selectedStage: Stage = .adaptation
    @State private var knowsSurgeryDate = false
    @State private var surgeryDate = Date.now

    @State private var healthKit = HealthKitManager.shared

    // Hydration
    @State private var knowsWeight = false
    @State private var weightLb: Double = 150
    @State private var weightFromHealth = false
    @State private var hydrationTargetML = 2000
    @State private var hasCustomizedTarget = false
    @State private var isConnectingHealth = false
    @State private var weightLookupMessage: String?

    // Reminders
    @State private var hydrationCadence: ReminderCadence = .default(for: .hydration)
    @State private var hydrationMinutes: [Int] = ReminderCadence.default(for: .hydration).times(for: .hydration)
    @State private var loggingCadence: ReminderCadence = .default(for: .logging)
    @State private var loggingMinutes: [Int] = ReminderCadence.default(for: .logging).times(for: .logging)
    @State private var notificationsDenied = false

    private var suggestedHydrationTargetML: Int {
        // Rough starting point, not a medical recommendation: ~15 mL per lb (~33 mL/kg,
        // a commonly cited general fluid guideline) plus a buffer for pouch fluid loss.
        let raw = Int(weightLb * 15) + 500
        return (raw / 250) * 250
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: JP.Spacing.xl) {
                ScrollView {
                    Group {
                        switch step {
                        case .welcome, .track, .privacy: welcomeSlide
                        case .stage: stageStep
                        case .health: healthStep
                        case .reminders: remindersStep
                        }
                    }
                    .padding(.top, JP.Spacing.xl)
                }

                // Sits just above the button, as the design has it, so the content above gets
                // the full height rather than losing a band of it to a progress bar.
                StepIndicator(current: step.rawValue, total: Step.allCases.count)
                    .padding(.horizontal, JP.Spacing.lg)

                Button(step == .reminders ? "Finish" : "Continue") {
                    advance()
                }
                .buttonStyle(.jpPrimary)
                .padding(.horizontal, JP.Spacing.lg)
                .padding(.bottom, JP.Spacing.xl)
            }
            .background(JP.Color.pageBackground)
        }
    }

    // MARK: - Welcome

    @ViewBuilder
    private var welcomeSlide: some View {
        if let slide = step.slide {
            VStack(spacing: JP.Spacing.xl) {
                Spacer(minLength: JP.Spacing.xl)

                // The opening slide leads with the app mark; the other two use a symbol in a
                // tile of the same footprint, so the three keep one rhythm rather than the
                // brand moment shrinking into a generic icon row.
                Group {
                    if let symbol = slide.symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(JP.Color.brandFill)
                            .frame(width: 96, height: 96)
                            // brandSurface is teal-50 — the same value as the page background,
                            // so a tile painted with it vanished and left the symbol floating.
                            .background(
                                JP.Color.brandSurfaceStrong,
                                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                            )
                    } else {
                        Image("AppMark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
                    }
                }
                // The title and body below say all of this; the mark is decoration.
                .accessibilityHidden(true)

                VStack(spacing: JP.Spacing.md) {
                    Text(slide.title)
                        .jpDisplayLarge()
                        .multilineTextAlignment(.center)
                    Text(slide.body)
                        .font(JP.Font.callout)
                        .foregroundStyle(JP.Color.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: JP.Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
            .padding(.horizontal, JP.Spacing.xl)
            // Without an identity per slide, SwiftUI reuses the same views and the copy swaps
            // in place with no sense of moving forward.
            .id(step)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Stage

    private var stageStep: some View {
        VStack(spacing: JP.Spacing.xl) {
            // At accessibility sizes the full-size header consumed most of the screen and
            // pushed every stage past the fold — including the one selected by default, so
            // there was no visible sign of what tapping Continue would choose. The cards
            // below each carry their own description, so the standfirst is the part to drop.
            VStack(spacing: JP.Spacing.sm) {
                Group {
                    // Was a second "Welcome to J-Pouch", which now repeats the first slide.
                    // The design names this step for the question it actually asks.
                    if dynamicTypeSize.isAccessibilitySize {
                        Text("Where are you right now?").font(JP.Font.title)
                    } else {
                        Text("Where are you right now?").jpDisplayLarge()
                    }
                }
                .multilineTextAlignment(.center)
                if !dynamicTypeSize.isAccessibilitySize {
                    Text("Tell us where you are in your journey so we only ask you about what's relevant right now.")
                        .font(JP.Font.callout)
                        .foregroundStyle(JP.Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: JP.Spacing.md) {
                ForEach(Stage.allCases) { stage in
                    Button {
                        selectedStage = stage
                    } label: {
                        StageOption(stage: stage, isSelected: selectedStage == stage)
                    }
                    .buttonStyle(.plain)
                    // Selection was conveyed only by the checkmark, so VoiceOver gave no way
                    // to tell which stage was chosen.
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(selectedStage == stage ? [.isButton, .isSelected] : .isButton)
                }
            }

            // Without a date there is nothing for the app to derive from, so it would be stuck
            // on whatever was picked here until the person went looking in Settings.
            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                Toggle("I know my \(selectedStage.promptedDateLabel.lowercased())", isOn: $knowsSurgeryDate)
                    .font(JP.Font.callout)
                if knowsSurgeryDate {
                    DatePicker(
                        selectedStage.promptedDateLabel,
                        selection: $surgeryDate,
                        displayedComponents: .date
                    )
                    .font(JP.Font.callout)
                }
                JPCaption("Optional, but it lets J-Pouch move you between stages on its own instead of waiting for you to update it.")
            }
            .jpCard()
        }
        .padding(.horizontal, JP.Spacing.lg)
    }

    private var stagedSurgeryDateValue: Date? {
        guard knowsSurgeryDate, selectedStage.promptedDate == .stagedSurgery else { return nil }
        return surgeryDate
    }

    private var takedownDateValue: Date? {
        guard knowsSurgeryDate, selectedStage.promptedDate == .takedown else { return nil }
        return surgeryDate
    }

    // MARK: - Apple Health and hydration target

    private var healthStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.xl) {
            StepHeader(
                title: "Connect Apple Health",
                subtitle: "One connection, and J-Pouch stops asking you for things your phone already knows."
            )

            healthConnectCard

            if let weightLookupMessage {
                JPCaption(weightLookupMessage)
            }

            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                JPCardHeader(title: "Weight", icon: "scalemass")
                // A lone unlabelled toggle gave no clue why weight was being asked for once
                // the medications block above it was removed.
                JPCaption("Only used to suggest a starting fluid target. Skip it and set the target yourself below.")
                Toggle("I'll enter my weight", isOn: $knowsWeight)
                    .toggleStyle(.jpCheckbox)

                if knowsWeight {
                    Stepper("Weight: \(Int(weightLb)) lb", value: $weightLb, in: 60...400, step: 1)
                        .font(JP.Font.body)
                    if weightFromHealth {
                        JPCaption("From Health — adjust if this isn't current.")
                    }
                    if !hasCustomizedTarget {
                        JPCaption("Suggested target: \(suggestedHydrationTargetML) mL/day")
                    }
                }
            }
            .jpCard()

            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                JPCardHeader(title: "Daily target", icon: "drop.fill")
                JPMetric(value: "\(hydrationTargetML)", unit: "mL/day")
                Stepper(
                    "Daily target",
                    value: $hydrationTargetML,
                    in: 500...5000,
                    step: 250
                )
                .labelsHidden()
                .font(JP.Font.body)
                // The figure is shown by JPMetric above, so the Stepper needs the value spelled
                // out for VoiceOver or it announces only "Daily target, adjustable".
                .accessibilityValue("\(hydrationTargetML) mL per day")
                JPCaption("This is a starting point, not medical advice — talk to your GI or dietitian for a number tailored to you, especially with high output.")
            }
            .jpCard()
        }
        .padding(.horizontal, JP.Spacing.lg)
        .onChange(of: weightLb) {
            if !hasCustomizedTarget {
                hydrationTargetML = suggestedHydrationTargetML
            }
        }
        .onChange(of: hydrationTargetML) {
            if hydrationTargetML != suggestedHydrationTargetML {
                hasCustomizedTarget = true
            }
        }
        .task {
            await healthKit.refreshConnectionState()
        }
    }

    /// The one ask on this step. Previously it sat under a "are you taking any medications?"
    /// yes/no that fed nothing but a draft form, above an "Open Health app" button offered
    /// before connecting — so tapping it accomplished nothing, since J-Pouch couldn't read
    /// anything from Health yet. Now there is a single action, with the reasons for it stated
    /// up front, and the Health app is only mentioned once it can actually do something.
    @ViewBuilder
    private var healthConnectCard: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            HStack(spacing: JP.Spacing.md) {
                JPIconCircle(systemImage: "heart.fill", tint: JP.Color.critical)
                VStack(alignment: .leading, spacing: JP.Spacing.xs) {
                    Text("Apple Health")
                        .font(JP.Font.headline)
                    if healthKit.connectionState == .connected {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(JP.Font.caption)
                            .foregroundStyle(JP.Color.confirmation)
                    }
                }
                Spacer(minLength: 0)
            }

            if healthKit.connectionState == .unavailable {
                JPCaption("Apple Health isn't available on this device. You can still enter your weight below and log everything by hand.")
            } else {
                VStack(alignment: .leading, spacing: JP.Spacing.sm) {
                    HealthBenefit(icon: "scalemass", text: "Reads your weight, so we can suggest a daily fluid target instead of guessing.")
                    if healthKit.supportsMedicationsAPI {
                        HealthBenefit(icon: "pills.fill", text: "Shows the medications you keep in Health, so you never type them twice.")
                    }
                    HealthBenefit(icon: "drop.fill", text: "Saves the water you log back to Health, alongside the rest of your health data.")
                }
                .padding(.vertical, JP.Spacing.xs)
            }

            if healthKit.connectionState == .connected {
                if healthKit.supportsMedicationsAPI {
                    JPCaption("Medications live in the Health app — add them under Browse → Medications and they'll appear in J-Pouch. Picking which ones to share is a separate prompt, so expect to be asked twice.")
                    Button("Open Health app") {
                        openURL(URL(string: "x-apple-health://")!)
                    }
                    .buttonStyle(.jpSecondary)
                } else {
                    JPCaption("This version of iOS can't share medications with apps, so you can add yours any time under Log → Meds.")
                }

                // Connecting and reading the weight can fail independently, so being
                // connected must not be a dead end when the value didn't come through.
                if !weightFromHealth {
                    Button {
                        Task { await loadWeightFromHealth() }
                    } label: {
                        if isConnectingHealth {
                            ProgressView()
                        } else {
                            Text("Use my weight from Health")
                        }
                    }
                    .buttonStyle(.jpSecondary)
                    .disabled(isConnectingHealth)
                }
            } else if healthKit.connectionState != .unavailable {
                // Covers .unknown as well as .notConnected. Unlike Settings, showing the
                // button before the check completes is the right default here: this is
                // first run, so almost nobody is connected yet, and the button is the
                // actionable choice either way.
                Button {
                    connectToHealth()
                } label: {
                    if isConnectingHealth {
                        ProgressView()
                    } else {
                        Text("Connect to Apple Health")
                    }
                }
                .buttonStyle(.jpSecondary)
                .disabled(isConnectingHealth)

                JPCaption("You can skip this and enter everything by hand — nothing here is required.")
            }
        }
        .jpCard()
    }

    private func connectToHealth() {
        isConnectingHealth = true
        Task {
            await healthKit.requestAuthorization()

            // Read the weight before asking about medications. That request presents its own
            // per-object sheet, and on iOS 26 the read grant is itself a two-sheet flow
            // (access, then how much history to share) — querying while sheets are still
            // coming and going returned nothing. Taking the value first, while we know the
            // read grant just settled, is both more reliable and better ordered.
            await loadWeightFromHealth()

            if healthKit.supportsMedicationsAPI {
                await healthKit.requestMedicationsAuthorization()
            }
            isConnectingHealth = false
        }
    }

    private func loadWeightFromHealth() async {
        isConnectingHealth = true
        defer { isConnectingHealth = false }
        do {
            guard let kg = try await healthKit.latestBodyMassKG() else {
                weightLookupMessage = "No weight found in Health — enter yours below."
                return
            }
            weightLb = (kg * 2.20462).rounded()
            weightFromHealth = true
            knowsWeight = true
            weightLookupMessage = nil
        } catch {
            // Distinct from having no data: a failed read is retryable, and telling someone
            // their weight isn't in Health when the query simply failed sends them off to
            // check the wrong thing.
            weightLookupMessage = "Couldn't read your weight from Health just now. Tap to try again, or enter it below."
        }
    }

    // MARK: - Reminders

    private var remindersStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.xl) {
            StepHeader(
                title: "Reminders",
                subtitle: "Sensible defaults are set already — adjust them now or later in Settings."
            )

            ReminderCadenceCard(kind: .hydration, cadence: $hydrationCadence, minutes: $hydrationMinutes)
            ReminderCadenceCard(kind: .logging, cadence: $loggingCadence, minutes: $loggingMinutes)

            if notificationsDenied {
                VStack(alignment: .leading, spacing: JP.Spacing.sm) {
                    Label("Notifications are turned off", systemImage: "bell.slash.fill")
                        .font(JP.Font.headline)
                        .foregroundStyle(JP.Color.attention)
                    // Without this the reminders look configured while nothing would ever
                    // arrive, which is worse than not offering them at all.
                    JPCaption("Your choices are saved, but nothing can be delivered until notifications are allowed for J-Pouch in the Settings app.")
                }
                .jpCard()
            } else {
                JPCaption("iOS will ask permission when you finish. Reminders only fire at the times shown — never overnight.")
            }
        }
        .padding(.horizontal, JP.Spacing.lg)
        .task {
            // Someone re-running onboarding after previously denying would otherwise be told
            // reminders are set when they can't be.
            let authorized = await NotificationManager.shared.isAuthorized()
            let canAsk = await NotificationManager.shared.canStillAsk()
            notificationsDenied = !authorized && !canAsk
        }
    }

    // MARK: - Navigation

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            finishOnboarding()
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) { step = next }
    }

    private func finishOnboarding() {
        let profile = UserProfile(
            manualStage: Stage.override(
                forPicked: selectedStage,
                stagedSurgeryDate: stagedSurgeryDateValue,
                takedownDate: takedownDateValue
            ),
            stagedSurgeryDate: stagedSurgeryDateValue,
            takedownDate: takedownDateValue,
            dailyHydrationTargetML: hydrationTargetML
        )
        profile.setReminders(for: .hydration, cadence: hydrationCadence, customMinutes: hydrationMinutes)
        profile.setReminders(for: .logging, cadence: loggingCadence, customMinutes: loggingMinutes)
        modelContext.insert(profile)

        // Snapshot the values before going async: the schedules are plain Ints, so nothing
        // carries a SwiftData model across the boundary.
        let schedules = [
            DailyReminderSchedule(kind: .hydration, minutes: profile.hydrationReminderMinutes),
            DailyReminderSchedule(kind: .logging, minutes: profile.loggingReminderMinutes),
        ]
        Task {
            // Asked here rather than on the reminders step so the prompt lands once the person
            // has finished choosing, not in the middle of it.
            guard schedules.contains(where: \.isOn) else { return }
            guard await NotificationManager.shared.requestAuthorization() else { return }
            await NotificationManager.shared.syncDailyReminders(schedules)
        }
    }
}

// MARK: - Pieces

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: JP.Spacing.sm) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? JP.Color.brandFill : JP.Color.separator)
                    // The current step widens into a pill, as the design shows, so position is
                    // readable without counting dots.
                    .frame(width: index == current ? 22 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: current)
        // These are now the only progress signal, the step count text having gone, so they
        // carry it for VoiceOver rather than being hidden as decoration.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

private struct HealthBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: JP.Spacing.sm) {
            Image(systemName: icon)
                .font(JP.Font.caption)
                .foregroundStyle(JP.Color.brandFill)
                .frame(width: 18)
                // Decorative: each icon repeats the sentence beside it.
                .accessibilityHidden(true)
            Text(text)
                .font(JP.Font.caption)
                .foregroundStyle(JP.Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            Text(title).jpDisplayMedium()
            Text(subtitle)
                .font(JP.Font.callout)
                .foregroundStyle(JP.Color.secondaryText)
        }
    }
}

private struct StageOption: View {
    let stage: Stage
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: JP.Spacing.md) {
            VStack(alignment: .leading, spacing: JP.Spacing.xs) {
                Text(stage.displayName)
                    .font(JP.Font.headline)
                    .foregroundStyle(JP.Color.primaryText)
                Text(stage.summary)
                    .font(JP.Font.caption)
                    .foregroundStyle(JP.Color.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(JP.Color.brandFill)
                    // The trait on the button already conveys this; without hiding it
                    // VoiceOver reads a redundant "checkmark circle fill".
                    .accessibilityHidden(true)
            }
        }
        .jpCard(tint: isSelected ? JP.Color.brandFill : nil)
    }
}

#Preview {
    OnboardingView()
}
