export const CHIP_STYLES = {
  bg: 'var(--op-chip-bg)',
  radius: 'var(--bn-border-radius)',
  gap: '6px',
  padding: {
    xxs: '2.5px 6px',
    xs: '1.5px 6px',
    s: '1.5px 6px',
  },

  fontSize: '12px',

  id: {
    color: 'var(--op-wp-meta-color)',
    fontWeight: 400,
  },

  type: {
    fontWeight: 600,
    letterSpacing: '0.04em',
    textTransform: 'uppercase' as const,
  },

  subject: {
    color: 'var(--bn-colors-highlights-blue-text)',
    fontWeight: 600,
    fontSize: '14px',
  },

  status: {
    bg: 'var(--op-status-bg)',
    border: '1px solid var(--op-status-border-color)',
    padding: '1px 8px',
    radius: '100px',
    color: 'var(--bn-colors-editor-text)',
    fontWeight: 600,
    gap: '4px',
    chevron: {
      color: 'var(--bn-colors-highlights-gray-text)',
      width: '7.29px',
      height: '3.90px',
    },
  },

  focusShadow: '0 0 0 4px var(--blocknote-focus-color)',
} as const;