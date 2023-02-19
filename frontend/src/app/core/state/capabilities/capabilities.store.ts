import { EntityStore, StoreConfig } from '@datorama/akita';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';

export interface CapabilitiesState extends CollectionState<ICapability> {
}

@StoreConfig({ name: 'capabilities' })
export class CapabilitiesStore extends EntityStore<CapabilitiesState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
