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

import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  templateUrl: './wp-breadcrumb.html',
  styleUrls: ['./wp-breadcrumb.sass'],
  selector: 'wp-breadcrumb',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WorkPackageBreadcrumbComponent {
  private I18n = inject(I18nService);
  private pathHelper = inject(PathHelperService);

  @Input() workPackage:WorkPackageResource;

  public text = {
    parent: this.I18n.t('js.relations_hierarchy.parent_headline'),
    hierarchy: this.I18n.t('js.relations_hierarchy.hierarchy_headline'),
  };

  public inputActive = false;

  public get hierarchyCount() {
    return this.workPackage.getAncestors().length;
  }

  public get hierarchyLabel() {
    return (this.hierarchyCount === 1) ? this.text.parent : this.text.hierarchy;
  }

  public ancestorPath(ancestor:WorkPackageResource):string {
    return this.pathHelper.genericWorkPackagePath(this.workPackage.project?.identifier, ancestor.displayId) + window.location.search;
  }

  public updateActiveInput(val:boolean) {
    this.inputActive = val;
  }
}
