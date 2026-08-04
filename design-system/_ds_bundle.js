/* @ds-bundle: {"format":4,"namespace":"JPouchDesignSystem_6e602e","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"StatCard","sourcePath":"components/core/StatCard.jsx"},{"name":"Tag","sourcePath":"components/core/Tag.jsx"},{"name":"Dialog","sourcePath":"components/feedback/Dialog.jsx"},{"name":"Toast","sourcePath":"components/feedback/Toast.jsx"},{"name":"Tooltip","sourcePath":"components/feedback/Tooltip.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"Radio","sourcePath":"components/forms/Radio.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"TabBar","sourcePath":"components/navigation/TabBar.jsx"},{"name":"Tabs","sourcePath":"components/navigation/Tabs.jsx"}],"sourceHashes":{"components/core/Badge.jsx":"91856d29b34b","components/core/Button.jsx":"ab8bf298cb0b","components/core/Card.jsx":"be180245dde2","components/core/Icon.jsx":"861199883df2","components/core/IconButton.jsx":"a2750029666f","components/core/StatCard.jsx":"ccd33587f8e1","components/core/Tag.jsx":"0c8f282d2b46","components/feedback/Dialog.jsx":"f85fab842b89","components/feedback/Toast.jsx":"97a9aab3b9c5","components/feedback/Tooltip.jsx":"af6bacda07e3","components/forms/Checkbox.jsx":"06833949b579","components/forms/Input.jsx":"dbbb1f02ac64","components/forms/Radio.jsx":"572b4fcd29e7","components/forms/Select.jsx":"36b059f5ecde","components/forms/Switch.jsx":"2c661776b948","components/navigation/TabBar.jsx":"be06c38950cc","components/navigation/Tabs.jsx":"7fb90e2699fa","ui_kits/mobile-app/Home.jsx":"b7b338e1b386","ui_kits/mobile-app/Insights.jsx":"e8207d49b6d1","ui_kits/mobile-app/LogEntry.jsx":"313bdb9579d1","ui_kits/mobile-app/Onboarding.jsx":"c9d74a457700","ui_kits/mobile-app/Profile.jsx":"3d80c20725dc"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.JPouchDesignSystem_6e602e = window.JPouchDesignSystem_6e602e || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Card({
  children,
  padding = 'var(--space-6)',
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      background: 'var(--color-surface)',
      border: '1px solid var(--color-border)',
      borderRadius: 'var(--radius-card)',
      boxShadow: 'var(--shadow-sm)',
      padding,
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const BASE = 'https://unpkg.com/lucide-static@0.462.0/icons/';
function Icon({
  name,
  size = 20,
  color = 'currentColor',
  style,
  className,
  ...rest
}) {
  const url = BASE + name + '.svg';
  return /*#__PURE__*/React.createElement("span", _extends({
    "aria-hidden": "true",
    className: className,
    style: {
      display: 'inline-block',
      width: size,
      height: size,
      flexShrink: 0,
      backgroundColor: color,
      WebkitMaskImage: `url(${url})`,
      maskImage: `url(${url})`,
      WebkitMaskSize: 'contain',
      maskSize: 'contain',
      WebkitMaskRepeat: 'no-repeat',
      maskRepeat: 'no-repeat',
      WebkitMaskPosition: 'center',
      maskPosition: 'center',
      ...style
    }
  }, rest));
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
const TONES = {
  neutral: {
    bg: 'var(--gray-100)',
    fg: 'var(--gray-700)'
  },
  success: {
    bg: 'var(--color-success-soft)',
    fg: 'var(--teal-700)'
  },
  warning: {
    bg: 'var(--color-warning-soft)',
    fg: 'var(--tan-700)'
  },
  danger: {
    bg: 'var(--color-danger-soft)',
    fg: 'var(--red-600)'
  },
  info: {
    bg: 'var(--color-info-soft)',
    fg: 'var(--blue-600)'
  }
};
function Badge({
  children,
  tone = 'neutral',
  icon,
  style
}) {
  const t = TONES[tone] || TONES.neutral;
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      background: t.bg,
      color: t.fg,
      fontFamily: 'var(--font-body)',
      fontWeight: 'var(--weight-semibold)',
      fontSize: 'var(--text-xs)',
      padding: '4px 10px',
      borderRadius: 'var(--radius-pill)',
      lineHeight: 1.4,
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 12,
    color: t.fg
  }), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const VARIANTS = {
  primary: {
    background: 'var(--color-primary)',
    color: 'var(--color-text-on-primary)',
    border: '1px solid transparent'
  },
  secondary: {
    background: 'var(--color-surface)',
    color: 'var(--color-primary)',
    border: '1px solid var(--color-border-strong)'
  },
  ghost: {
    background: 'transparent',
    color: 'var(--color-primary)',
    border: '1px solid transparent'
  },
  danger: {
    background: 'var(--color-danger)',
    color: 'var(--white)',
    border: '1px solid transparent'
  }
};
const HOVER = {
  primary: {
    background: 'var(--color-primary-hover)'
  },
  secondary: {
    background: 'var(--color-primary-soft)'
  },
  ghost: {
    background: 'var(--color-primary-soft)'
  },
  danger: {
    background: '#8a3c2c'
  }
};
const SIZES = {
  sm: {
    padding: '8px 14px',
    fontSize: 'var(--text-sm)',
    borderRadius: 'var(--radius-button)',
    gap: 6
  },
  md: {
    padding: '12px 20px',
    fontSize: 'var(--text-md)',
    borderRadius: 'var(--radius-button)',
    gap: 8
  },
  lg: {
    padding: '16px 26px',
    fontSize: 'var(--text-lg)',
    borderRadius: 'var(--radius-button)',
    gap: 10
  }
};
function Button({
  children,
  variant = 'primary',
  size = 'md',
  icon,
  iconPosition = 'left',
  disabled,
  style,
  ...rest
}) {
  const v = VARIANTS[variant] || VARIANTS.primary;
  const h = HOVER[variant] || HOVER.primary;
  const s = SIZES[size] || SIZES.md;
  return /*#__PURE__*/React.createElement("button", _extends({
    disabled: disabled,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: s.gap,
      fontFamily: 'var(--font-body)',
      fontWeight: 'var(--weight-semibold)',
      fontSize: s.fontSize,
      padding: s.padding,
      borderRadius: s.borderRadius,
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.45 : 1,
      transition: `background var(--duration-fast) var(--ease-out), transform var(--duration-fast) var(--ease-out)`,
      ...v,
      ...style
    },
    "style-hover": !disabled ? h : {},
    "style-active": !disabled ? {
      transform: 'scale(0.98)'
    } : {}
  }, rest), icon && iconPosition === 'left' && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: s.fontSize === 'var(--text-lg)' ? 20 : 16
  }), children, icon && iconPosition === 'right' && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: s.fontSize === 'var(--text-lg)' ? 20 : 16
  }));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const SIZES = {
  sm: 32,
  md: 40,
  lg: 48
};
const VARIANTS = {
  filled: {
    background: 'var(--color-primary)',
    color: 'var(--color-text-on-primary)'
  },
  soft: {
    background: 'var(--color-primary-soft)',
    color: 'var(--color-primary)'
  },
  ghost: {
    background: 'transparent',
    color: 'var(--color-text-secondary)'
  }
};
function IconButton({
  icon,
  label,
  variant = 'ghost',
  size = 'md',
  style,
  ...rest
}) {
  const dim = SIZES[size] || SIZES.md;
  const v = VARIANTS[variant] || VARIANTS.ghost;
  return /*#__PURE__*/React.createElement("button", _extends({
    "aria-label": label,
    style: {
      width: dim,
      height: dim,
      borderRadius: 'var(--radius-pill)',
      border: 'none',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer',
      transition: 'background var(--duration-fast) var(--ease-out), transform var(--duration-fast) var(--ease-out)',
      ...v,
      ...style
    },
    "style-hover": {
      background: variant === 'filled' ? 'var(--color-primary-hover)' : 'var(--color-primary-soft)'
    },
    "style-active": {
      transform: 'scale(0.94)'
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: dim * 0.5
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/StatCard.jsx
try { (() => {
function StatCard({
  label,
  value,
  unit,
  icon,
  trend,
  tone = 'neutral',
  style
}) {
  const trendColor = trend > 0 ? 'var(--color-success)' : trend < 0 ? 'var(--color-danger)' : 'var(--color-text-muted)';
  return /*#__PURE__*/React.createElement(__ds_scope.Card, {
    padding: "var(--space-5)",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      minWidth: 150,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 16,
    color: "var(--color-primary)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-xs)',
      color: 'var(--color-text-muted)',
      fontWeight: 'var(--weight-medium)'
    }
  }, label)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-3xl)',
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--color-text-primary)'
    }
  }, value), unit && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-sm)',
      color: 'var(--color-text-muted)'
    }
  }, unit)), trend !== undefined && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-2xs)',
      color: trendColor,
      fontWeight: 'var(--weight-medium)'
    }
  }, trend > 0 ? '↑' : trend < 0 ? '↓' : '—', " ", Math.abs(trend), "% vs last week"));
}
Object.assign(__ds_scope, { StatCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/StatCard.jsx", error: String((e && e.message) || e) }); }

// components/core/Tag.jsx
try { (() => {
function Tag({
  children,
  active = false,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      fontWeight: 'var(--weight-medium)',
      padding: '7px 14px',
      borderRadius: 'var(--radius-pill)',
      cursor: onClick ? 'pointer' : 'default',
      border: active ? '1px solid var(--color-primary)' : '1px solid var(--color-border-strong)',
      background: active ? 'var(--color-primary-soft)' : 'var(--color-surface)',
      color: active ? 'var(--teal-700)' : 'var(--color-text-secondary)',
      transition: 'background var(--duration-fast) var(--ease-out)',
      ...style
    },
    "style-hover": {
      background: 'var(--color-primary-soft)'
    }
  }, children);
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tag.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Dialog.jsx
try { (() => {
function Dialog({
  open,
  title,
  children,
  onClose,
  footer
}) {
  if (!open) return null;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(28,33,31,0.4)',
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'center',
      zIndex: 50
    },
    onClick: onClose
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      width: '100%',
      maxWidth: 420,
      background: 'var(--color-surface)',
      borderRadius: '24px 24px 0 0',
      boxShadow: 'var(--shadow-lg)',
      padding: 'var(--space-6)',
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-bold)',
      fontSize: 'var(--text-xl)',
      color: 'var(--color-text-primary)'
    }
  }, title), /*#__PURE__*/React.createElement(__ds_scope.IconButton, {
    icon: "x",
    label: "Close",
    variant: "ghost",
    size: "sm",
    onClick: onClose
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-secondary)'
    }
  }, children), footer && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10,
      justifyContent: 'flex-end'
    }
  }, footer)));
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Toast.jsx
try { (() => {
const TONES = {
  neutral: {
    icon: 'info',
    color: 'var(--color-primary)'
  },
  success: {
    icon: 'check-circle',
    color: 'var(--color-success)'
  },
  danger: {
    icon: 'alert-circle',
    color: 'var(--color-danger)'
  }
};
function Toast({
  message,
  tone = 'neutral',
  onClose,
  style
}) {
  const t = TONES[tone] || TONES.neutral;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      background: 'var(--gray-900)',
      color: 'var(--white)',
      padding: '13px 16px',
      borderRadius: 'var(--radius-md)',
      boxShadow: 'var(--shadow-lg)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      maxWidth: 340,
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: t.icon,
    size: 17,
    color: t.color
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }, message), onClose && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "x",
    size: 15,
    color: "var(--gray-400)",
    style: {
      cursor: 'pointer'
    },
    onClick: onClose
  }));
}
Object.assign(__ds_scope, { Toast });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Toast.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Tooltip.jsx
try { (() => {
function Tooltip({
  children,
  label,
  style
}) {
  const [open, setOpen] = React.useState(false);
  return /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'relative',
      display: 'inline-flex'
    },
    onMouseEnter: () => setOpen(true),
    onMouseLeave: () => setOpen(false)
  }, children, open && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      bottom: '125%',
      left: '50%',
      transform: 'translateX(-50%)',
      background: 'var(--gray-900)',
      color: 'var(--white)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-xs)',
      padding: '6px 10px',
      borderRadius: 'var(--radius-sm)',
      whiteSpace: 'nowrap',
      boxShadow: 'var(--shadow-md)',
      zIndex: 10,
      ...style
    }
  }, label));
}
Object.assign(__ds_scope, { Tooltip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Tooltip.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
function Checkbox({
  label,
  checked,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-primary)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("input", {
    type: "checkbox",
    checked: checked,
    onChange: onChange,
    style: {
      display: 'none'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 22,
      height: 22,
      borderRadius: 7,
      flexShrink: 0,
      border: `1px solid ${checked ? 'var(--color-primary)' : 'var(--color-border-strong)'}`,
      background: checked ? 'var(--color-primary)' : 'var(--color-surface)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      transition: 'background var(--duration-fast) var(--ease-out)'
    }
  }, checked && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check",
    size: 14,
    color: "var(--white)"
  })), label);
}
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Input({
  label,
  helper,
  error,
  prefix,
  suffix,
  mono,
  style,
  id,
  ...rest
}) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, '-');
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement("label", {
    htmlFor: inputId,
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--color-text-secondary)'
    }
  }, label), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      background: 'var(--color-surface)',
      border: `1px solid ${error ? 'var(--color-danger)' : 'var(--color-border-strong)'}`,
      borderRadius: 'var(--radius-input)',
      padding: '11px 14px'
    }
  }, prefix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--color-text-muted)',
      fontSize: 'var(--text-sm)'
    }
  }, prefix), /*#__PURE__*/React.createElement("input", _extends({
    id: inputId,
    style: {
      border: 'none',
      outline: 'none',
      flex: 1,
      background: 'transparent',
      fontFamily: mono ? 'var(--font-mono)' : 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-primary)'
    }
  }, rest)), suffix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--color-text-muted)',
      fontSize: 'var(--text-sm)'
    }
  }, suffix)), (helper || error) && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-xs)',
      color: error ? 'var(--color-danger)' : 'var(--color-text-muted)'
    }
  }, error || helper));
}
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/Radio.jsx
try { (() => {
function Radio({
  label,
  checked,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-primary)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("input", {
    type: "radio",
    checked: checked,
    onChange: onChange,
    style: {
      display: 'none'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 22,
      height: 22,
      borderRadius: '50%',
      flexShrink: 0,
      border: `1px solid ${checked ? 'var(--color-primary)' : 'var(--color-border-strong)'}`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, checked && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 11,
      height: 11,
      borderRadius: '50%',
      background: 'var(--color-primary)'
    }
  })), label);
}
Object.assign(__ds_scope, { Radio });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Radio.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
function Select({
  label,
  value,
  onChange,
  options,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement("label", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--color-text-secondary)'
    }
  }, label), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("select", {
    value: value,
    onChange: onChange,
    style: {
      width: '100%',
      appearance: 'none',
      border: '1px solid var(--color-border-strong)',
      borderRadius: 'var(--radius-input)',
      padding: '11px 38px 11px 14px',
      background: 'var(--color-surface)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-primary)'
    }
  }, options.map(o => /*#__PURE__*/React.createElement("option", {
    key: o.value,
    value: o.value
  }, o.label))), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron-down",
    size: 16,
    color: "var(--color-text-muted)",
    style: {
      position: 'absolute',
      right: 14,
      top: '50%',
      transform: 'translateY(-50%)',
      pointerEvents: 'none'
    }
  })));
}
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
function Switch({
  checked,
  onChange,
  label,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-primary)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("input", {
    type: "checkbox",
    checked: checked,
    onChange: onChange,
    style: {
      display: 'none'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 42,
      height: 26,
      borderRadius: 'var(--radius-pill)',
      flexShrink: 0,
      position: 'relative',
      background: checked ? 'var(--color-primary)' : 'var(--gray-200)',
      transition: 'background var(--duration-normal) var(--ease-out)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 3,
      left: checked ? 19 : 3,
      width: 20,
      height: 20,
      borderRadius: '50%',
      background: 'var(--white)',
      boxShadow: 'var(--shadow-xs)',
      transition: 'left var(--duration-normal) var(--ease-out)'
    }
  })), label);
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/navigation/TabBar.jsx
try { (() => {
function TabBar({
  items,
  active,
  onChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      background: 'rgba(255,255,255,0.85)',
      backdropFilter: 'blur(var(--blur-glass))',
      WebkitBackdropFilter: 'blur(var(--blur-glass))',
      borderTop: '1px solid var(--color-border)',
      padding: '8px 4px calc(8px + env(safe-area-inset-bottom, 0px))'
    }
  }, items.map(it => /*#__PURE__*/React.createElement("button", {
    key: it.value,
    onClick: () => onChange && onChange(it.value),
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 4,
      border: 'none',
      background: 'none',
      cursor: 'pointer',
      padding: '6px 0',
      color: active === it.value ? 'var(--color-primary)' : 'var(--color-text-muted)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: it.icon,
    size: 22,
    color: active === it.value ? 'var(--color-primary)' : 'var(--color-text-muted)'
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-2xs)',
      fontWeight: 'var(--weight-medium)'
    }
  }, it.label))));
}
Object.assign(__ds_scope, { TabBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/TabBar.jsx", error: String((e && e.message) || e) }); }

// components/navigation/Tabs.jsx
try { (() => {
function Tabs({
  items,
  active,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 4,
      background: 'var(--gray-100)',
      padding: 4,
      borderRadius: 'var(--radius-pill)',
      ...style
    }
  }, items.map(it => /*#__PURE__*/React.createElement("button", {
    key: it.value,
    onClick: () => onChange && onChange(it.value),
    style: {
      flex: 1,
      border: 'none',
      padding: '8px 16px',
      borderRadius: 'var(--radius-pill)',
      cursor: 'pointer',
      fontFamily: 'var(--font-body)',
      fontWeight: 'var(--weight-semibold)',
      fontSize: 'var(--text-sm)',
      background: active === it.value ? 'var(--color-surface)' : 'transparent',
      color: active === it.value ? 'var(--color-primary)' : 'var(--color-text-muted)',
      boxShadow: active === it.value ? 'var(--shadow-xs)' : 'none',
      transition: 'background var(--duration-fast) var(--ease-out)'
    }
  }, it.label)));
}
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/Tabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile-app/Home.jsx
try { (() => {
const {
  Card,
  StatCard,
  Badge,
  Icon,
  IconButton
} = window.JPouchDesignSystem_6e602e;
const ENTRIES = [{
  time: '7:12 AM',
  consistency: 'Formed',
  note: ''
}, {
  time: '11:40 AM',
  consistency: 'Loose',
  note: 'After coffee'
}, {
  time: '3:05 PM',
  consistency: 'Formed',
  note: ''
}];
function Header({
  title,
  subtitle
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 'var(--space-6) var(--space-5) var(--space-4)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-extrabold)',
      fontSize: 'var(--text-2xl)',
      color: 'var(--color-text-primary)',
      letterSpacing: 'var(--tracking-tight)'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      color: 'var(--color-text-muted)',
      marginTop: 4
    }
  }, subtitle));
}
function Home({
  onOpenEntry
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      overflowY: 'auto',
      background: 'var(--color-bg)'
    }
  }, /*#__PURE__*/React.createElement(Header, {
    title: "Good afternoon",
    subtitle: "12 weeks since takedown"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 var(--space-5)',
      display: 'flex',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(StatCard, {
    label: "Output today",
    value: 3,
    unit: "times",
    icon: "activity",
    trend: -12,
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(StatCard, {
    label: "Hydration",
    value: "1.4",
    unit: "L",
    icon: "droplets",
    trend: 8,
    style: {
      flex: 1
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 'var(--space-6) var(--space-5) var(--space-3)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-bold)',
      fontSize: 'var(--text-lg)',
      color: 'var(--color-text-primary)'
    }
  }, "Today's log"), /*#__PURE__*/React.createElement(Badge, {
    tone: "success",
    icon: "check"
  }, "On track")), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 var(--space-5)',
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, ENTRIES.map((e, i) => /*#__PURE__*/React.createElement(Card, {
    key: i,
    padding: "14px 16px",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      background: 'var(--color-primary-soft)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "droplet",
    size: 16,
    color: "var(--color-primary)"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--color-text-primary)'
    }
  }, e.consistency, e.note && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--color-text-muted)',
      fontWeight: 'var(--weight-regular)'
    }
  }, " \xB7 ", e.note))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-xs)',
      color: 'var(--color-text-muted)'
    }
  }, e.time)))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 'var(--space-6) var(--space-5)'
    }
  }, /*#__PURE__*/React.createElement(Card, {
    padding: "14px 16px",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      cursor: 'pointer'
    },
    onClick: onOpenEntry
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "pill",
    size: 18,
    color: "var(--color-accent-hover)"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      color: 'var(--color-text-primary)'
    }
  }, "Time for your evening dose of loperamide."), /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron-right",
    label: "Details",
    size: "sm",
    variant: "ghost"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 90
    }
  }));
}
window.Home = Home;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile-app/Home.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile-app/Insights.jsx
try { (() => {
const {
  Card,
  Tabs,
  Icon
} = window.JPouchDesignSystem_6e602e;
const WEEK = [2, 4, 3, 5, 3, 2, 4];
const DAYS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
function Insights() {
  const [range, setRange] = React.useState('w');
  const max = Math.max(...WEEK);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      overflowY: 'auto',
      background: 'var(--color-bg)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 'var(--space-6) var(--space-5) var(--space-4)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-extrabold)',
      fontSize: 'var(--text-2xl)',
      color: 'var(--color-text-primary)',
      letterSpacing: 'var(--tracking-tight)',
      marginBottom: 14
    }
  }, "Insights"), /*#__PURE__*/React.createElement(Tabs, {
    items: [{
      label: 'Week',
      value: 'w'
    }, {
      label: 'Month',
      value: 'm'
    }],
    active: range,
    onChange: setRange
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 var(--space-5)'
    }
  }, /*#__PURE__*/React.createElement(Card, null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      color: 'var(--color-text-muted)',
      marginBottom: 16
    }
  }, "Output per day"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-end',
      gap: 10,
      height: 100
    }
  }, WEEK.map((v, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      maxWidth: 26,
      height: `${v / max * 80}px`,
      background: 'var(--color-primary)',
      borderRadius: 6
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-2xs)',
      color: 'var(--color-text-muted)'
    }
  }, DAYS[i]))))), /*#__PURE__*/React.createElement(Card, {
    style: {
      marginTop: 16,
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "trending-down",
    size: 20,
    color: "var(--color-success)"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      color: 'var(--color-text-primary)'
    }
  }, "Output frequency is trending down compared to last week."))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 90
    }
  }));
}
window.Insights = Insights;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile-app/Insights.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile-app/LogEntry.jsx
try { (() => {
const {
  Button,
  Input,
  Select,
  Checkbox,
  IconButton
} = window.JPouchDesignSystem_6e602e;
const SYMPTOMS = ['Cramping', 'Nausea', 'Urgency', 'Bloating'];
function LogEntry({
  onBack,
  onSave
}) {
  const [consistency, setConsistency] = React.useState('formed');
  const [symptoms, setSymptoms] = React.useState([]);
  const toggle = s => setSymptoms(v => v.includes(s) ? v.filter(x => x !== s) : [...v, s]);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      background: 'var(--color-surface)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      padding: 'var(--space-5)',
      borderBottom: '1px solid var(--color-border)'
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron-left",
    label: "Back",
    variant: "ghost",
    onClick: onBack
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-bold)',
      fontSize: 'var(--text-lg)',
      color: 'var(--color-text-primary)'
    }
  }, "Log output")), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: 'var(--space-5)',
      display: 'flex',
      flexDirection: 'column',
      gap: 'var(--space-5)'
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Time",
    mono: true,
    defaultValue: "3:42 PM"
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Consistency",
    value: consistency,
    onChange: e => setConsistency(e.target.value),
    options: [{
      label: 'Liquid',
      value: 'liquid'
    }, {
      label: 'Loose',
      value: 'loose'
    }, {
      label: 'Formed',
      value: 'formed'
    }]
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-sm)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--color-text-secondary)',
      marginBottom: 10
    }
  }, "Symptoms (optional)"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, SYMPTOMS.map(s => /*#__PURE__*/React.createElement(Checkbox, {
    key: s,
    label: s,
    checked: symptoms.includes(s),
    onChange: () => toggle(s)
  })))), /*#__PURE__*/React.createElement(Input, {
    label: "Note",
    placeholder: "Anything else worth remembering?"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 'var(--space-5)',
      borderTop: '1px solid var(--color-border)'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "lg",
    style: {
      width: '100%'
    },
    onClick: onSave
  }, "Save entry")));
}
window.LogEntry = LogEntry;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile-app/LogEntry.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile-app/Onboarding.jsx
try { (() => {
const {
  Button,
  Icon
} = window.JPouchDesignSystem_6e602e;
const SLIDES = [{
  icon: 'heart-pulse',
  title: 'Welcome to J-Pouch',
  body: "Your companion for j-pouch surgery, recovery, and life after — one place to track how you're doing."
}, {
  icon: 'activity',
  title: 'Track what matters',
  body: 'Output, hydration, medications, and symptoms — logged in seconds, so you can spot patterns instead of guessing.'
}, {
  icon: 'shield-check',
  title: 'Private, and yours',
  body: 'Your data stays with you. Share a summary with your care team only when you choose to.'
}];
function Onboarding({
  onDone
}) {
  const [i, setI] = React.useState(0);
  const s = SLIDES[i];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      height: '100%',
      background: 'var(--color-bg)',
      padding: 'var(--space-7) var(--space-6)',
      boxSizing: 'border-box'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 'var(--space-6)',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 88,
      height: 88,
      borderRadius: '50%',
      background: 'var(--color-primary-soft)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: s.icon,
    size: 40,
    color: "var(--color-primary)"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-extrabold)',
      fontSize: 'var(--text-2xl)',
      color: 'var(--color-text-primary)',
      marginBottom: 10,
      letterSpacing: 'var(--tracking-tight)'
    }
  }, s.title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-secondary)',
      lineHeight: 'var(--leading-relaxed)',
      maxWidth: 300
    }
  }, s.body))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      gap: 6,
      marginBottom: 'var(--space-6)'
    }
  }, SLIDES.map((_, idx) => /*#__PURE__*/React.createElement("div", {
    key: idx,
    style: {
      width: idx === i ? 20 : 6,
      height: 6,
      borderRadius: 3,
      background: idx === i ? 'var(--color-primary)' : 'var(--gray-200)',
      transition: 'width var(--duration-normal) var(--ease-out)'
    }
  }))), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "lg",
    style: {
      width: '100%'
    },
    onClick: () => i < SLIDES.length - 1 ? setI(i + 1) : onDone()
  }, i < SLIDES.length - 1 ? 'Continue' : 'Get started'));
}
window.Onboarding = Onboarding;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile-app/Onboarding.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile-app/Profile.jsx
try { (() => {
const {
  Card,
  Switch,
  Icon,
  Badge
} = window.JPouchDesignSystem_6e602e;
function Row({
  icon,
  label,
  right
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '14px 0',
      borderBottom: '1px solid var(--color-border)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: icon,
    size: 18,
    color: "var(--color-text-secondary)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-md)',
      color: 'var(--color-text-primary)'
    }
  }, label), right);
}
function Profile() {
  const [hydration, setHydration] = React.useState(true);
  const [meds, setMeds] = React.useState(true);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      overflowY: 'auto',
      background: 'var(--color-bg)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 'var(--space-6) var(--space-5) var(--space-4)',
      display: 'flex',
      alignItems: 'center',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 56,
      height: 56,
      borderRadius: '50%',
      background: 'var(--color-primary)',
      color: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-bold)',
      fontSize: 'var(--text-lg)'
    }
  }, "A"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-bold)',
      fontSize: 'var(--text-lg)',
      color: 'var(--color-text-primary)'
    }
  }, "Alex"), /*#__PURE__*/React.createElement(Badge, {
    tone: "info"
  }, "Adjustment phase"))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 var(--space-5)'
    }
  }, /*#__PURE__*/React.createElement(Card, {
    padding: "0 16px"
  }, /*#__PURE__*/React.createElement(Row, {
    icon: "droplets",
    label: "Hydration reminders",
    right: /*#__PURE__*/React.createElement(Switch, {
      checked: hydration,
      onChange: e => setHydration(e.target.checked)
    })
  }), /*#__PURE__*/React.createElement(Row, {
    icon: "pill",
    label: "Medication reminders",
    right: /*#__PURE__*/React.createElement(Switch, {
      checked: meds,
      onChange: e => setMeds(e.target.checked)
    })
  }), /*#__PURE__*/React.createElement(Row, {
    icon: "ruler",
    label: "Units",
    right: /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: 'var(--font-mono)',
        fontSize: 'var(--text-sm)',
        color: 'var(--color-text-muted)'
      }
    }, "Metric")
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 0'
    }
  }, /*#__PURE__*/React.createElement(Row, {
    icon: "share-2",
    label: "Share summary with care team",
    right: /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 16,
      color: "var(--color-text-muted)"
    })
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 90
    }
  }));
}
window.Profile = Profile;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile-app/Profile.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.StatCard = __ds_scope.StatCard;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.Toast = __ds_scope.Toast;

__ds_ns.Tooltip = __ds_scope.Tooltip;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.Radio = __ds_scope.Radio;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.TabBar = __ds_scope.TabBar;

__ds_ns.Tabs = __ds_scope.Tabs;

})();
