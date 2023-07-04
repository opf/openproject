/**
 * Return an <i> HTML element with the given icon classes
 * and aria-hidden=true set.
 */
export function spotIconElement(name:string, size?:string) {
  const icon = document.createElement('span');
  icon.setAttribute('aria-hidden', 'true');
  icon.classList.add('spot-icon', `spot-icon_${name}`);
  if (size) {
    icon.classList.add(`spot-icon_${size}`);
  }

  return icon;
}
