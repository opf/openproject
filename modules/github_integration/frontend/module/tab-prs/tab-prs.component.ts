//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from "core-app/features/hal/resources/work-package-resource";
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from "core-app/features/hal/services/hal-resource.service";
import { CollectionResource } from "core-app/features/hal/resources/collection-resource";
import { IGithubPullRequestResource } from "../../../../../../../../modules/github_integration/frontend/module/typings";
import { I18nService } from "core-app/core/i18n/i18n.service";

@Component({
  selector: 'tab-prs',
  templateUrl: './tab-prs.template.html',
  host: { class: 'op-prs' }
})
export class TabPrsComponent implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  public pullRequests:IGithubPullRequestResource[] = [];

  constructor(
    readonly I18n:I18nService,
    readonly apiV3Service:APIV3Service,
    readonly halResourceService:HalResourceService,
    readonly changeDetector:ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    const pullRequestsPath = this.apiV3Service.work_packages.id({id: this.workPackage.id })?.github_pull_requests.path;

    this.halResourceService
      .get<CollectionResource<IGithubPullRequestResource>>(pullRequestsPath)
      .subscribe((value) => {
        this.pullRequests = value.elements;
        this.changeDetector.detectChanges();
      });
  }

  public getEmptyText() {
    return this.I18n.t('js.github_integration.tab_prs.empty',{ wp_id: this.workPackage.id });
  }
}
