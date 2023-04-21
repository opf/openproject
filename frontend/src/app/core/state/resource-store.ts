import {
  applyTransaction,
  EntityState,
  EntityStore,
  ID,
} from '@datorama/akita';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IHalResourceLinks } from 'core-app/core/state/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { filter } from 'lodash';

export interface CollectionResponse {
  ids:ID[];
}

export interface ResourceState<T> extends EntityState<T> {
  /** Loaded notification collections */
  collections:Record<string, CollectionResponse>;

  /** Loading resources, collections or singular entities */
  loadingResources:Record<string, boolean>;
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
 * Initialize the resource part of the entity store
 */
export function createInitialResourceState<T>():ResourceState<T> {
  return {
    collections: {},
    loadingResources: {},
  };
}

/**
 * Mark a resource path as being loaded
 *
 * @param store An entity store for the collection
 * @param url The resource path to mark as loading
 */
export function setResourceLoading<T extends { id:ID }>(
  store:EntityStore<ResourceState<T>>,
  url:string,
):void {
  store.update(({ loadingResources }) => (
    {
      loadingResources: {
        ...loadingResources,
        [url]: true,
      },
    }
  ));
}

/**
 * Mark a resource path as no longer loading
 *
 * @param store An entity store for the collection
 * @param url The resource path to unmark as loading
 */
export function removeResourceLoading<T extends { id:ID }>(
  store:EntityStore<ResourceState<T>>,
  url:string,
):void {
  store.update(({ loadingResources }) => (
    {
      loadingResources: filter(loadingResources, (_, key) => key !== url),
    }
  ));
}

/**
 * Insert a collection into the given entity store
 *
 * @param store An entity store for the collection
 * @param collection A loaded collection
 * @param collectionUrl The key to insert the collection at
 */
export function insertCollectionIntoState<T extends { id:ID }>(
  store:EntityStore<ResourceState<T>>,
  collection:IHALCollection<T>,
  collectionUrl:string,
):void {
  const { elements } = collection._embedded as { elements:undefined|T[] };

  // Some JSON endpoints return no elements result if there are no elements
  const ids = elements?.map((el) => el.id) || [];

  applyTransaction(() => {
    // Avoid inserting when elements is not defined
    if (elements && elements.length > 0) {
      store.upsertMany(elements);
    }

    store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [collectionUrl]: {
            ids,
          },
        },
      }
    ));
  });
}

export function removeEntityFromCollectionAndState<T extends { id:ID }>(
  store:EntityStore<ResourceState<T>>,
  entityId:ID,
  collectionUrl:string,
):void {
  applyTransaction(() => {
    store.remove(entityId);
    store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [collectionUrl]: {
            ...collections[collectionUrl],
            ids: (collections[collectionUrl]?.ids || []).filter((id) => id !== entityId),
          },
        },
      }
    ));
  });
}

export function collectionFrom<T>(elements:T[]):IHALCollection<T> {
  const count = elements.length;

  return {
    _type: 'Collection',
    count,
    total: count,
    pageSize: count,
    offset: 1,
    _embedded: {
      elements,
    },
  };
}

/**
 * Takes a collection of elements that do not have an ID, and extract the ID from self link.
 * @param collection a IHALCollection with elements that have a self link
 * @returns the same collection with elements extended with an ID derived from the self link.
 */
export function extendCollectionElementsWithId<T extends { _links:IHalResourceLinks }>(
  collection:IHALCollection<T>,
):IHALCollection<T&{ id:ID }> {
  const elements = collection._embedded.elements.map((element) => ({
    ...element,
    id: idFromLink(element._links.self.href),
  }));

  return {
    ...collection,
    _embedded: {
      ...collection._embedded,
      elements,
    },
  };
}
