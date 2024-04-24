import { EntityStore, StoreConfig } from '@datorama/akita';
import { IGithubPullRequest } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.model';
import {
  createInitialResourceState,
  ResourceState,
} from 'core-app/core/state/resource-store';

export interface GithubPullRequestsState extends ResourceState<IGithubPullRequest> {
}

@StoreConfig({ name: 'github-pull-requests' })
export class GithubPullRequestsStore extends EntityStore<GithubPullRequestsState> {
  constructor() {
    super(createInitialResourceState());
  }
}
