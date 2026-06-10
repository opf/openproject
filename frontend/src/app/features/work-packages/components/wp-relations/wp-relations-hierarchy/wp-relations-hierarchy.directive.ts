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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { withLatestFrom } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

@Component({
  selector: 'wp-relations-hierarchy',
  templateUrl: './wp-relations-hierarchy.template.html',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WorkPackageRelationsHierarchyComponent extends UntilDestroyedMixin implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly PathHelper = inject(PathHelperService);
  readonly I18n = inject(I18nService);
  readonly schemaCache = inject(SchemaCacheService);
  readonly cdRef = inject(ChangeDetectorRef);

  @Input() public workPackage:WorkPackageResource;

  @Input() public relationType:string;

  public showEditForm = false;

  public workPackagePath:string;

  public canHaveChildren = false;

  public canModifyHierarchy:boolean;

  public canAddRelation:boolean;

  public childrenQueryProps:any;

  public text = {
    parentHeadline: this.I18n.t('js.relations_hierarchy.parent_headline'),
    childrenHeadline: this.I18n.t('js.relations_hierarchy.children_headline'),
  };

  ngOnInit() {
    this.workPackagePath = this.PathHelper.workPackagePath(this.workPackage.displayId);
    this.canModifyHierarchy = !!this.workPackage.changeParent;
    this.canAddRelation = !!this.workPackage.addRelation;

    this.childrenQueryProps = {
      filters: JSON.stringify([{ parent: { operator: '=', values: [this.workPackage.id] } }]),
      'columns[]': ['id', 'type', 'subject', 'status'],
      showHierarchies: false,
    };

    this
      .apiV3Service
      .work_packages
      .id(this.workPackage)
      .requireAndStream()
      .pipe(
        withLatestFrom(this.schemaCache.requireAndStream(this.schemaCache.getSchemaHref(this.workPackage)!)),
        this.untilDestroyed(),
      )
      .subscribe(([wp, _]) => {
        const milestone = this.schemaCache.of(wp).isMilestone as boolean;
        this.workPackage = wp;
        this.canHaveChildren = !milestone;

        this.cdRef.detectChanges();
      });
  }
}
