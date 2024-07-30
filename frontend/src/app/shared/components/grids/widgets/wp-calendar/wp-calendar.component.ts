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

import { ChangeDetectionStrategy, Component, Injector } from '@angular/core';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './wp-calendar.component.html',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
})
export class WidgetWpCalendarComponent extends AbstractWidgetComponent {
  text = {
    missing_permission: this.I18n.t('js.grid.widgets.missing_permission'),
  };

  hasCapability$ = this.currentUser.hasCapabilities$('work_packages/read', this.currentProject.id);

  constructor(
    protected readonly I18n:I18nService,
    protected readonly injector:Injector,
    protected readonly currentProject:CurrentProjectService,
    protected readonly currentUser:CurrentUserService,
  ) {
    super(I18n, injector);
  }

  public get projectIdentifier() {
    return this.currentProject.identifier;
  }
}
