//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2023 Ben Tey
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
// Copyright (C) the OpenProject GmbH
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
import { HalResourceService } from "core-app/features/hal/services/hal-resource.service";
import { CollectionResource } from "core-app/features/hal/resources/collection-resource";
import { I18nService } from "core-app/core/i18n/i18n.service";
import {IGitlabIssueResource} from "core-app/features/plugins/linked/openproject-gitlab_integration/typings";
import {ApiV3Service} from "core-app/core/apiv3/api-v3.service";

@Component({
  selector: 'tab-issue',
  templateUrl: './tab-issue.template.html',
  host: { class: 'op-issue' }
})
export class TabIssueComponent implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  public gitlabIssues:IGitlabIssueResource[] = [];

  constructor(
    readonly I18n:I18nService,
    readonly apiV3Service:ApiV3Service,
    readonly halResourceService:HalResourceService,
    readonly changeDetector:ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    const basePath = this.apiV3Service.work_packages.id(this.workPackage.id as string).path;
    const gitlabIssuePath = `${basePath}/gitlab_issues`;

    this.halResourceService
      .get<CollectionResource<IGitlabIssueResource>>(gitlabIssuePath)
      .subscribe((value) => {
        this.gitlabIssues = value.elements;
        this.changeDetector.detectChanges();
      });
  }

  public getEmptyText() {
    return this.I18n.t('js.gitlab_integration.tab_issue.empty',{ wp_id: this.workPackage.id });
  }
}
