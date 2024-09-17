import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';

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

/**
 * Detect the origin of a clicked link
 * @param evt
 * @param linkElement
 */
export function openExternalLinksInNewTab(evt:MouseEvent, linkElement:HTMLAnchorElement):boolean {
  if (isClickedWithModifier(evt)) {
    return false;
  }

  const link = linkElement.href || '';

  if (link === '' || !!linkElement.download) {
    return false;
  }

  const origin = window.location.origin;

  try {
    const url = new URL(link, window.location.origin);
    if (origin !== url.origin) {
      window.open(link, '_blank', 'noopener,noreferrer');
      return true;
    }
  } catch (_) {
    // Do nothing if the url is invalid.
    return false;
  }

  return false;
}
