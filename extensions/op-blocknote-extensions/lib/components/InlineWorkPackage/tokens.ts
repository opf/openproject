// Design tokens for inline work-package chips.
// Edit values here all components pick them up automatically.

export const TOKEN = {
  chip: {
    bg: "#F6F8FA",
    radius: "6px",
    gap: "6px",
    padding: {
      xxs: "2px 8px 2px 8px",
      xs: "8px",
      s: "8px",
    },
  },

  fontSize: "12px",

  id: {
    color: "#636C76",
    fontWeight: 400,
  },

  type: {
    color:         "var(--op-inline-wp-type-color, #d97706)",
    fontWeight:    700,
    letterSpacing: "0.04em",
    textTransform: "uppercase" as const,
  },

  subject: {
    color: "var(--op-inline-wp-subject-link-color, #1a67a3)",
    fontWeight: 600,
  },

  status: {
    bg: "#CAF7CA",
    border: "1px solid rgba(84, 174, 255, 0.40)",
    padding: "1px 8px",
    radius: "100px",
    color:"#1F2328",
    fontWeight: 600,
    chevron: {
      color: "#636C76",
      width: "7.29px",
      height: "3.90px",
    },
  },

  // Matches the exact outline applied to block-level WP card on focus
  focusOutline: "4px solid rgb(100, 160, 255)",
  focusShadow: "none",
} as const;