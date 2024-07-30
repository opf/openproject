// -- copyright
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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.

import { CUSTOM_ELEMENTS_SCHEMA, Injector, NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { MeetingsTabComponent } from './meetings-tab/meetings-tab.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HttpClient } from '@angular/common/http';
import { filter, map, startWith, switchMap, throttleTime } from 'rxjs/operators';
import { fromEvent, merge, Observable } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TurboStreamElement } from 'core-typings/turbo';

export function workPackageMeetingsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const pathHelperService = injector.get(PathHelperService);
  const http = injector.get(HttpClient);

  return merge(
    fromEvent(document, 'turbo:frame-render'),
    fromEvent(document, 'turbo:before-stream-render'),
  )
    .pipe(
      filter((event:CustomEvent) => {
        if (event.type === 'turbo:frame-render') {
          return (event.target as HTMLElement).id?.includes('work-package-meetings-tab');
        }

        if (event.type === 'turbo:before-stream-render') {
          const stream:TurboStreamElement = (event.detail as { newStream:TurboStreamElement }).newStream;
          return stream.target?.includes('work-package-meetings-tab');
        }

        return false;
      }),
      startWith(null),
      throttleTime(1000),
      switchMap(() => {
        return http
          .get(`${pathHelperService.workPackagePath(workPackage.id as string)}/meetings/tab/count`)
          .pipe(
            map((res:{ count:number }) => res.count),
          );
      }),
    );
}

export function initializeMeetingPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  const I18n = injector.get(I18nService);
  wpTabService.register({
    component: MeetingsTabComponent,
    name: I18n.t('js.label_meetings'),
    id: 'meetings',
    displayable: (workPackage) => !!workPackage.meetings,
    count: workPackageMeetingsCount,
  });
}

@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectTabsModule,
  ],
  declarations: [
    MeetingsTabComponent,
  ],
  exports: [
    MeetingsTabComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class PluginModule {
  constructor(injector:Injector) {
    initializeMeetingPlugin(injector);
  }
}
