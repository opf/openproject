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
  Component,
  OnInit,
} from '@angular/core';
import {
  WidgetAbstractMenuComponent,
} from 'core-app/shared/components/grids/widgets/menu/widget-abstract-menu.component';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { take } from 'rxjs/operators';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'op-widget-project-details-menu',
  templateUrl: '../menu/widget-menu.component.html',
})
export class WidgetProjectDetailsMenuComponent extends WidgetAbstractMenuComponent implements OnInit {
  @InjectField() pathHelper:PathHelperService;

  @InjectField() currentProject:CurrentProjectService;

  @InjectField() currentUser:CurrentUserService;

  private capabilityPromise:Promise<boolean>;

  ngOnInit():void {
    this.capabilityPromise = firstValueFrom(
      this.currentUser
        .hasCapabilities$('activities/read', this.currentProject.id)
        .pipe(take(1)),
    );
  }

  protected async buildItems():Promise<OpContextMenuItem[]> {
    const items = [
      this.removeItem,
    ];
    if (await this.capabilityPromise) {
      items.push(this.projectActivityLinkItem);
    }
    return items;
  }

  protected get projectActivityLinkItem():OpContextMenuItem {
    const projectActivityPath = this.pathHelper.projectActivityPath(this.currentProject.identifier as string);
    return {
      linkText: this.i18n.t('js.project.details_activity'),
      href: `${projectActivityPath}?event_types[]=project_attributes`,
    };
  }
}
