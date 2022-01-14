/**
 * Capitalize
 */
export function addParamToHref(href:string, params:Record<string, string>):string {
  const url = new URL(href, window.location.origin);

  Object
    .keys(params)
    .forEach((key) => {
      url.searchParams.set(key, params[key]);
    });

  return url.pathname + url.search;
}
