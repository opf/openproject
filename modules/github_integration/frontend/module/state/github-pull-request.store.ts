import { EntityStore, StoreConfig } from '@datorama/akita';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';
import { IGithubPullRequest } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.model';

export interface GithubPullRequestsState extends CollectionState<IGithubPullRequest> {
}

@StoreConfig({ name: 'github-pull-requests' })
export class GithubPullRequestsStore extends EntityStore<GithubPullRequestsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
