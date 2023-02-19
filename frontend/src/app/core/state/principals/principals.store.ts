import { EntityStore, StoreConfig } from '@datorama/akita';
import { IPrincipal } from './principal.model';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';

export interface PrincipalsState extends CollectionState<IPrincipal> {
}

@StoreConfig({ name: 'principals' })
export class PrincipalsStore extends EntityStore<PrincipalsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
