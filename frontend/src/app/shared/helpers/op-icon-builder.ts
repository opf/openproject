import { toDOMString } from '@openproject/octicons-angular';

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

/**
 * Return an <i> HTML element with the octicon SVG inside
 * aria-hidden=true is set
 */
export function octiconElement(iconData:any, size:'xsmall'|'small' = 'small', classes = '', title = '') {
  const iconString:string = toDOMString(
    iconData, // SVG data for the icon.
    size,
    { 'aria-hidden': 'true',
      class: classes,
      title: title},
  );
  const icon = document.createElement('i');
  icon.innerHTML = iconString;

  return icon;
}
