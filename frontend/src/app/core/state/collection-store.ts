import {
  EntityState,
  ID,
  QueryEntity,
} from '@datorama/akita';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import {
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { Observable } from 'rxjs';
import {
  filter,
} from 'rxjs/operators';

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

export function mapHALCollectionToIDCollection<T extends CollectionItem>(collection:IHALCollection<T>):CollectionResponse {
  return {
    ids: collection._embedded.elements.map((el) => el.id),
  };
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
export function collectionKey(params:ApiV3ListParameters):string {
  return listParamsString(params);
}

/**
 * Retrieve a collection from the given parameter set.
 *
 * @param service
 * @param params
 */
export function selectCollectionAsHrefs$<T extends CollectionItem>(service:CollectionService<T>, params:ApiV3ListParameters):Observable<CollectionResponse> {
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
 * Retrieve the entities from the collection a given the ID collection
 *
 * @param service
 * @param collection
 */
export function selectEntitiesFromIDCollection<T extends CollectionItem>(service:CollectionService<T>, collection:CollectionResponse):T[] {
  const ids = collection?.ids || [];

  return ids
    .map((id) => service.query.getEntity(id))
    .filter((item) => !!item) as T[];
}

/**
 * Retrieve the entities from the collection a given parameter set produces.
 *
 * @param service
 * @param state
 * @param params
 */
export function selectCollectionAsEntities$<T extends CollectionItem>(service:CollectionService<T>, params:ApiV3ListParameters):T[] {
  const state = service.query.getValue();
  const key = collectionKey(params);
  const collection = state.collections[key];

  return selectEntitiesFromIDCollection(service, collection);
}
