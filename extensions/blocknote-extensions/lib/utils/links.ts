export function newTabLinkProps(href:string) {
  return { href, target: '_blank' as const, rel: 'noopener noreferrer' };
}
