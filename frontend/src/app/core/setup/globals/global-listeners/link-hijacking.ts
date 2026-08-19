/**
 * Our application is still a hybrid one, meaning most routes are still
 * handled by Rails. As such, we disable the default link-hijacking that
 * Angular's HTML5-mode with <base href="/"> results in
 * @param evt
 * @param linkElement
 */
export function performAnchorHijacking(evt:MouseEvent, linkElement:HTMLAnchorElement):boolean {
  const link = linkElement.getAttribute('href') || '';
  const hashPos = link.indexOf('#');

  // If link is neither empty nor starts with hash, ignore it
  if (link !== '' && hashPos !== 0) {
    return false;
  }

  // Set the location to the hash if there is any
  // Since with the base tag, links like href="#whatever" otherwise target to <base>/#whatever
  if (hashPos !== -1 && link !== '#') {
    window.location.hash = link;
  }

  return true;
}
