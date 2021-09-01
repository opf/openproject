import { EntityState, ID, QueryEntity } from '@datorama/akita';
import { Apiv3ListParameters, listParamsString } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { Observable } from 'rxjs';
import { filter, switchMap } from 'rxjs/operators';

export interface CollectionResponse {
  ids:ID[];
}

export interface CollectionState<T> extends EntityState<T> {
  /** Loaded notification collections */
  collections:Record<string, CollectionResponse>;
}

export interface CollectionService<T> {
  query:QueryEntity<CollectionState<T>>;
}

export interface CollectionItem {
  id:ID;
}

/**
 * Initialize the collection part of the entity store
 */
export function createInitialCollectionState():{ collections:Record<string, CollectionResponse> } {
  return {
    collections: {},
  };
}

/**
 * Returns the collection key for the given APIv3 parameters
 *
 * @param params list params
 */
export function collectionKey(params:Apiv3ListParameters):string {
  return listParamsString(params);
}

/**
 * Retrieve a collection from the given parameter set.
 *
 * @param service
 * @param params
 */
export function selectCollection$<T extends CollectionItem>(service:CollectionService<T>, params:Apiv3ListParameters):Observable<CollectionResponse> {
  return service
    .query
    .select((state) => {
      const collection = collectionKey(params);
      return state?.collections[collection];
    })
    .pipe(
      filter((collection) => !!collection),
    );
}

/**
 * Retrieve the entities from the collection a given parameter set produces.
 *
 * @param service
 * @param params
 */
export function selectCollectionEntities$<T extends CollectionItem>(service:CollectionService<T>, params:Apiv3ListParameters):Observable<T[]> {
  return selectCollection$<T>(service, params)
    .pipe(
      switchMap((collection:CollectionResponse) => (
        service.query.selectAll({
          filterBy: ({ id }) => collection.ids.includes(id),
        })
      )),
    );
}
