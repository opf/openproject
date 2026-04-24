export const CHIP_STYLES = {
  bg: "var(--bn-colors-highlights-gray-background)",
  radius: "var(--bn-border-radius)",
  gap: "6px",
  padding: {
    xxs: "2px 6px",
    xs: "1px 6px",
    s: "1px 6px",
  },

  fontSize: "12px",

  id: {
    color: "var(--bn-colors-highlights-gray-text)",
    fontWeight: 400,
  },

  type: {
    fontWeight: 600,
    letterSpacing: "0.04em",
    textTransform: "uppercase" as const,
  },

  subject: {
    color: "var(--bn-colors-highlights-blue-text)",
    fontWeight: 600,
    fontSize: "14px",
  },

  status: {
    bg: "var(--op-status-bg)",
    border: "1px solid var(--op-status-border-color)",
    padding: "1px 8px",
    radius: "100px",
    color: "var(--bn-colors-editor-text)",
    fontWeight: 600,
    gap: "4px",
    chevron: {
      color: "var(--bn-colors-highlights-gray-text)",
      width: "7.29px",
      height: "3.90px",
    },
  },

  focusOutline: "4px solid var(--mantine-color-blue-4)",
  focusShadow: "none",
} as const;