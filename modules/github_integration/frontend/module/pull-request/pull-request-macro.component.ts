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
import { map } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PullRequestState } from './pull-request-state.component';

export const githubPullRequestMacroSelector = 'macro.github_pull_request';

@Component({
  selector: githubPullRequestMacroSelector,
  templateUrl: './pull-request-macro.component.html',
  styleUrls: ['./pull-request-macro.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class PullRequestMacroComponent implements OnInit {
  @Input() pullRequestId:string;

  @Input() pullRequestState:PullRequestState;

  pullRequest$:Observable<IGithubPullRequest>;

  displayText$:Observable<string>;

  constructor(
    readonly elementRef:ElementRef,
    readonly injector:Injector,
    readonly pullRequests:GithubPullRequestResourceService,
    readonly I18n:I18nService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.pullRequest$ = this
      .pullRequests
      .requireSingle(this.pullRequestId);

    this.displayText$ = this
      .pullRequest$
      .pipe(
        map((pr) => this.buildText(pr)),
      );
  }

  private buildText(pr:IGithubPullRequest):string {
    const githubUserLink = this.htmlLink(pr._embedded.githubUser.htmlUrl, pr._embedded.githubUser.login);
    const repositoryLink = this.htmlLink(pr.repositoryHtmlUrl, pr.repository);
    const prLink = this.htmlLink(pr.htmlUrl, pr.title);

    const message = this.pullRequestState === 'referenced' ? 'referenced_message' : 'message';
    return this.I18n.t(
      `js.github_integration.pull_requests.${message}`,
      {
        pr_number: pr.number,
        pr_link: prLink,
        repository_link: repositoryLink,
        pr_state: this.I18n.t(
          `js.github_integration.pull_requests.states.${this.pullRequestState}`,
          { defaultValue: this.pullRequestState || '(unknown state)' },
        ),
        github_user_link: githubUserLink,
      },
    );
  }

  private htmlLink(href:string, title:string):string {
    const link = document.createElement('a');
    link.href = href;
    link.textContent = title;

    return link.outerHTML;
  }
}
