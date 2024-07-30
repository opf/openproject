//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
//++

import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
  Input,
  OnInit,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GithubPullRequestResourceService } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.service';
import { IGithubPullRequest } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.model';
import {
  map,
  shareReplay,
} from 'rxjs/operators';
import { Observable } from 'rxjs';

@Component({
  selector: 'op-tab-prs',
  templateUrl: './tab-prs.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TabPrsComponent implements OnInit {
  @HostBinding('class.op-github-prs') className = true;

  @Input() workPackage:WorkPackageResource;

  pullRequests$:Observable<IGithubPullRequest[]>;

  emptyText:string;

  constructor(
    readonly I18n:I18nService,
    readonly apiV3Service:ApiV3Service,
    readonly githubPullRequests:GithubPullRequestResourceService,
  ) {}

  ngOnInit():void {
    this.emptyText = this.I18n.t('js.github_integration.tab_prs.empty', { wp_id: this.workPackage.id });
    this.pullRequests$ = this
      .githubPullRequests
      .ofWorkPackage(this.workPackage)
      .pipe(
        map((elements) => _.sortBy(elements, 'updatedAt')),
        shareReplay(1),
      );
  }
}
