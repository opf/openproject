import { EntityStore, StoreConfig } from '@datorama/akita';
import { IPrincipal } from './principal.model';
import { ResourceState, createInitialResourceState } from 'core-app/core/state/resource-store';

export interface PrincipalsState extends ResourceState<IPrincipal> {
}

@StoreConfig({ name: 'principals' })
export class PrincipalsStore extends EntityStore<PrincipalsState> {
  constructor() {
    super(createInitialResourceState());
  }
}
