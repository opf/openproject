import { EntityStore, StoreConfig } from '@datorama/akita';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';
import { Project } from './project.model';

export interface ProjectsState extends CollectionState<Project> {
}

@StoreConfig({ name: 'projects' })
export class ProjectsStore extends EntityStore<ProjectsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
