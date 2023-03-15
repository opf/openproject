// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
// ++    Ng1FieldControlsWrapper,

import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit,
} from '@angular/core';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { IGithubPullRequest } from '../state/github-pull-request.model';
import { GithubPullRequestResourceService } from '../state/github-pull-request.service';
import { Observable } from 'rxjs';

export const githubPullRequestMacroSelector = 'macro.github_pull_request';

export type PullRequestState = 'opened'|'closed'|'referenced'|'ready_for_review'|'merged'|'draft';

@Component({
  selector: githubPullRequestMacroSelector,
  templateUrl: './pull-request-macro.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class PullRequestMacroComponent implements OnInit {
  @Input() pullRequestId:string;

  @Input() pullRequestState:PullRequestState;

  pullRequest$:Observable<IGithubPullRequest>;

  constructor(
    readonly elementRef:ElementRef,
    readonly injector:Injector,
    readonly pullRequests:GithubPullRequestResourceService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.pullRequest$ = this
      .pullRequests
      .requireSingle(this.pullRequestId);
  }
}
