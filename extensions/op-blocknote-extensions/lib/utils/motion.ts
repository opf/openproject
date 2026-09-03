export const wantsMotion = ():boolean =>
  !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
