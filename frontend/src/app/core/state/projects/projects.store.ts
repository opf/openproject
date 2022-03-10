import { EntityStore, StoreConfig } from '@datorama/akita';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';
import { IProject } from './project.model';

export interface ProjectsState extends CollectionState<IProject> {
}

@StoreConfig({ name: 'projects' })
export class ProjectsStore extends EntityStore<ProjectsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
