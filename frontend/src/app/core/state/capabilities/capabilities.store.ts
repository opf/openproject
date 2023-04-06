import { EntityStore, StoreConfig } from '@datorama/akita';
import { ResourceState, createInitialResourceState } from 'core-app/core/state/resource-store';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';

export interface CapabilitiesState extends ResourceState<ICapability> {
}

@StoreConfig({ name: 'capabilities' })
export class CapabilitiesStore extends EntityStore<CapabilitiesState> {
  constructor() {
    super(createInitialResourceState());
  }
}
