// BlockNote layers its own floating UI at `--bn-ui-base-z-index` + 10..90 (formatting
// toolbar 40, link toolbar 50); staying on that scale keeps ours inside the editor's
// layer instead of above the host app's header and tabs.
export const FLOATING_Z_INDEX = {
  preview: 'calc(var(--bn-ui-base-z-index, 0) + 40)',
  search: 'calc(var(--bn-ui-base-z-index, 0) + 50)',
  options: 'calc(var(--bn-ui-base-z-index, 0) + 50)',
} as const;
