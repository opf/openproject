/**
 * Our application is still a hybrid one, meaning most routes are still
 * handled by Rails. As such, we disable the default link-hijacking that
 * Angular's HTML5-mode with <base href="/"> results in
 * @param evt
 * @param target
 */
export function performAnchorHijacking(evt:JQueryEventObject, target:JQuery):boolean {
  // Avoid defaulting clicks on elements already removed from DOM
  if (!document.contains(evt.target)) {
    evt.preventDefault();
  }

  // Avoid handling clicks on anything other than a
  const linkElement = target.closest('a');
  if (linkElement.length === 0) {
    return true;
  }

  const link = linkElement.attr('href') || '';
  const hashPos = link.indexOf('#');

  // If link is neither empty nor starts with hash, ignore it
  if (link !== '' && hashPos === -1) {
    return true;
  }

  // Set the location to the hash if there is any
  // Since with the base tag, links like href="#whatever" otherwise target to <base>/#whatever
  if (hashPos !== -1 && link !== '#') {
    window.location.hash = link;
  }

  evt.preventDefault();
  return false;
}
