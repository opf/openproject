export function hashPrefixForSize(size:string | undefined):string {
  if (size === 'xxs') return '#';
  if (size === 'xs') return '##';
  return '###'; // s, m, l, xl, undefined
}

export function buildExternalDOM(
  tag:'div' | 'span',
  attrs:Record<string, string>,
  text:string,
  doc:Document,
  href:string,
):HTMLElement {
  const element = doc.createElement(tag);
  for (const [name, value] of Object.entries(attrs)) {
    element.setAttribute(name, value);
  }
  const a = doc.createElement('a');
  a.setAttribute('href', href);
  a.textContent = text;
  element.appendChild(a);
  return element;
}
