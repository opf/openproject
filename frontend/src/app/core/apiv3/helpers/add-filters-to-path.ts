import {
  ApiV3Filter,
  ApiV3FilterBuilder,
} from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

/**
 * Add or append filters to a given base URL.
 * If the URL already had filters, it is appending them, overriding existing filters with the same key.
 *
 * @param basePath The base path to add filters to.
 * @param filters An ApiV3FilterBuilder object containing the filters to add.
 * @param params Additional query parameters to add, if any.
 */
export function addFiltersToPath(
  basePath:string,
  filters:ApiV3FilterBuilder,
  params:{ [key:string]:string } = {},
):URL {
  const url = new URL(basePath, window.location.origin);

  if (url.searchParams.has('filters')) {
    const existingFilters = JSON.parse(url.searchParams.get('filters') as string) as ApiV3Filter[];
    url.searchParams.set('filters', JSON.stringify(existingFilters.concat(filters.filters)));
  } else {
    url.searchParams.set('filters', filters.toJson());
  }

  Object
    .keys(params)
    .forEach((key) => {
      url.searchParams.set(key, params[key]);
    });

  return url;
}
