import { EntityStore, StoreConfig } from '@datorama/akita';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';
import { View } from './view.model';

export interface ViewsState extends CollectionState<View> {
}

@StoreConfig({ name: 'views' })
export class ViewsStore extends EntityStore<ViewsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
