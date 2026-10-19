// True when the primary pointer can hover (desktop mouse) rather than a touch
// screen like iOS - used to branch touch-specific behaviour.
export function supportsHover():boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(hover: hover)').matches
  );
}
