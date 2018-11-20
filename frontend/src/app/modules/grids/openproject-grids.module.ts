// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {NgModule, APP_INITIALIZER, Injector} from '@angular/core';
import {WidgetWpAssignedComponent} from "core-components/grid/widgets/wp-assigned/wp-assigned.component";
import {WidgetWpCreatedComponent} from "core-components/grid/widgets/wp-created/wp-created.component";
import {WidgetWpWatchedComponent} from "core-components/grid/widgets/wp-watched/wp-watched.component";
import {WidgetWpCalendarComponent} from "core-components/grid/widgets/wp-calendar/wp-calendar.component";
import {DynamicModule} from 'ng-dynamic-component';
import {GridComponent} from "core-components/grid/grid.component";
import {AddGridWidgetModal} from "core-components/grid/widgets/add/add.modal";
import {AddGridWidgetService} from "core-components/grid/widgets/add/add.service";
import {GridWidgetsService} from "core-components/grid/widgets/widgets.service";
import {HookService} from "core-app/modules/plugins/hook-service";
import {MyPageComponent} from "core-components/routing/my-page/my-page.component";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {BrowserModule} from '@angular/platform-browser';
import {FormsModule} from '@angular/forms';
import {DragDropModule} from '@angular/cdk/drag-drop';
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";

@NgModule({
  imports: [
    BrowserModule,
    FormsModule,
    DragDropModule,

    OpenprojectCommonModule,
    OpenprojectWorkPackagesModule,
    //Grids
    DynamicModule.withComponents([WidgetWpAssignedComponent,
                                  WidgetWpCreatedComponent,
                                  WidgetWpWatchedComponent,
                                  WidgetWpCalendarComponent]),
  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: registerWidgets,
      deps: [Injector],
      multi: true
    },
    GridWidgetsService,
    AddGridWidgetService
  ],
  declarations: [
    GridComponent,
    WidgetWpAssignedComponent,
    WidgetWpCreatedComponent,
    WidgetWpWatchedComponent,
    WidgetWpCalendarComponent,
    AddGridWidgetModal,

    // MyPage
    MyPageComponent,
  ],
  entryComponents: [
    WidgetWpAssignedComponent,
    WidgetWpCreatedComponent,
    WidgetWpWatchedComponent,
    AddGridWidgetModal,

    // MyPage
    MyPageComponent,
  ],
  exports: [
  ]
})
export class OpenprojectGridsModule {
}

export function registerWidgets(injector:Injector) {
  return () => {
    const hookService = injector.get(HookService);
    hookService.register('gridWidgets', () => {
      return [
        {
          identifier: 'work_packages_assigned',
          component: WidgetWpAssignedComponent
        },
        {
          identifier: 'work_packages_created',
          component: WidgetWpCreatedComponent
        },
        {
          identifier: 'work_packages_watched',
          component: WidgetWpWatchedComponent
        },
        {
          identifier: 'work_packages_calendar',
          component: WidgetWpCalendarComponent
        }
      ];
    });
  };
}
