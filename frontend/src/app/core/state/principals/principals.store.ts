import { EntityStore, StoreConfig } from '@datorama/akita';
import { Principal } from './principal.model';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';

export interface PrincipalsState extends CollectionState<Principal> {
}

@StoreConfig({ name: 'principals' })
export class PrincipalsStore extends EntityStore<PrincipalsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
