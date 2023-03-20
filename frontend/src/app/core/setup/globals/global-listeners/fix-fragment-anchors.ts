/**
 * Due to having a <base /> tag, links that only contains anchors break as they
 * reference the application base url + the anchor instead of the current page.
 */
export function fixFragmentAnchors():void {
  // Get current document URL without any existing fragments
  const baseUrl = document.location.href.replace(/#.*$/, '');

  Array
    .from(document.getElementsByTagName('A'))
    .forEach((el:HTMLAnchorElement) => {
      const href = el.getAttribute('href') as string;

      if (href && href !== '#' && href.startsWith('#')) {
        el.setAttribute('href', baseUrl + href);
      }
    });
}
