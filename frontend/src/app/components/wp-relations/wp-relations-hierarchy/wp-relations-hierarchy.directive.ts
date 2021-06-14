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

import { Component, Input, OnInit } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { WorkPackageRelationsHierarchyService } from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { take } from 'rxjs/operators';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Component({
  selector: 'wp-relations-hierarchy',
  templateUrl: './wp-relations-hierarchy.template.html'
})
export class WorkPackageRelationsHierarchyComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public relationType:string;

  public showEditForm = false;
  public workPackagePath:string;
  public canHaveChildren:boolean;
  public canModifyHierarchy:boolean;
  public canAddRelation:boolean;

  public childrenQueryProps:any;

  constructor(protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected apiV3Service:APIV3Service,
              protected PathHelper:PathHelperService,
              readonly I18n:I18nService) {
    super();
  }

  public text = {
    parentHeadline: this.I18n.t('js.relations_hierarchy.parent_headline'),
    childrenHeadline: this.I18n.t('js.relations_hierarchy.children_headline'),
  };

  ngOnInit() {
    this.workPackagePath = this.PathHelper.workPackagePath(this.workPackage.id!);
    this.canModifyHierarchy = !!this.workPackage.changeParent;
    this.canAddRelation = !!this.workPackage.addRelation;

    this.childrenQueryProps = {
      filters: JSON.stringify([{ parent: { operator: '=', values: [this.workPackage.id] } }]),
      'columns[]': ['id', 'type', 'subject', 'status'],
      showHierarchies: false
    };

    this
      .apiV3Service
      .work_packages
      .id(this.workPackage)
      .requireAndStream()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;

        const parentId = this.workPackage.parent?.id?.toString();

        if (parentId) {
          this
            .apiV3Service
            .work_packages
            .id(parentId)
            .get()
            .pipe(
              take(1)
            )
            .subscribe((parent:WorkPackageResource) => {
              this.workPackage.parent = parent;
            });
        }
      });
  }
}
