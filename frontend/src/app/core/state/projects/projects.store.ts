import { EntityStore, StoreConfig } from '@datorama/akita';
import { ResourceState, createInitialResourceState } from 'core-app/core/state/resource-store';
import { IProject } from './project.model';

export interface ProjectsState extends ResourceState<IProject> {
}

@StoreConfig({ name: 'projects' })
export class ProjectsStore extends EntityStore<ProjectsState> {
  constructor() {
    super(createInitialResourceState());
  }
}
