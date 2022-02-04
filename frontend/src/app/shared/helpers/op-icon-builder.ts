/**
 * Return an <i> HTML element with the given icon classes
 * and aria-hidden=true set.
 */
export function opIconElement(...classes:string[]) {
  const icon = document.createElement('i');
  icon.setAttribute('aria-hidden', 'true');
  icon.classList.add(...classes);

  return icon;
}
