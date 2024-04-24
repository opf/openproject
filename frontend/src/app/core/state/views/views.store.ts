import { EntityStore, StoreConfig } from '@datorama/akita';
import { ResourceState, createInitialResourceState } from 'core-app/core/state/resource-store';
import { IView } from './view.model';

export interface ViewsState extends ResourceState<IView> {
}

@StoreConfig({ name: 'views' })
export class ViewsStore extends EntityStore<ViewsState> {
  constructor() {
    super(createInitialResourceState());
  }
}
