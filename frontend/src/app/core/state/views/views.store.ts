import { EntityStore, StoreConfig } from '@datorama/akita';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';
import { IView } from './view.model';

export interface ViewsState extends CollectionState<IView> {
}

@StoreConfig({ name: 'views' })
export class ViewsStore extends EntityStore<ViewsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
