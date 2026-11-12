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

  focusShadow: '0 0 0 4px var(--blocknote-focus-color)',
  // Inline chips draw the selection ring mostly inward (so it doesn't cover adjacent characters and
  // the chip stays flush at line starts) plus a thin 1px outward band so it reads like a slightly
  // smaller version of the block card ring. Keeping it mostly inset is what removes the need for a
  // horizontal margin that would otherwise indent the chip at line starts.
  inlineFocusShadow:
    'inset 0 0 0 2px var(--blocknote-focus-color), 0 0 0 1px var(--blocknote-focus-color)',
} as const;