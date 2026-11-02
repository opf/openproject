// Test management: "Testing" tab on work packages (full view and split view).
//
// Linked into the core frontend build by
//   bin/rails openproject:plugins:register_frontend
// (creates frontend/src/app/features/plugins/linked/openproject-test_management
// and regenerates linked-plugins.module.ts). The tab content is server-rendered
// by TestManagement::WorkPackageTestingTabController inside a <turbo-frame>.

import { CUSTOM_ELEMENTS_SCHEMA, Injector, NgModule, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { fromEvent, Observable } from 'rxjs';
import { filter, map, startWith, switchMap, throttleTime } from 'rxjs/operators';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TestingTabComponent } from './testing-tab/testing-tab.component';

export const TESTING_TAB_FRAME_ID = 'work-package-testing-tab-content';

export function testingTabBasePath(pathHelper:PathHelperService, workPackage:WorkPackageResource):string {
  return `${pathHelper.workPackagePath(workPackage.id as string)}/test_management/tab`;
}

export function workPackageTestingCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const pathHelper = injector.get(PathHelperService);
  const http = injector.get(HttpClient);

  return fromEvent(document, 'turbo:frame-render')
    .pipe(
      filter((event:Event) => (event.target as HTMLElement | null)?.id === TESTING_TAB_FRAME_ID),
      startWith(null),
      throttleTime(1000),
      switchMap(() => http
        .get<{ count:number }>(`${testingTabBasePath(pathHelper, workPackage)}/count`)
        .pipe(map((res) => res.count))),
    );
}

export function initializeTestManagementPlugin(injector:Injector):void {
  const wpTabService = injector.get(WorkPackageTabsService);
  const I18n = injector.get(I18nService);

  wpTabService.registerAfter(
    'relations',
    {
      component: TestingTabComponent,
      name: I18n.t('js.work_packages.tabs.testing', { defaultValue: 'Testing' }),
      id: 'testing',
      // _links.testing is only rendered when the module is enabled in the work
      // package's project and the user has :show_testing_content there.
      displayable: (workPackage) => !!workPackage.testing,
      count: workPackageTestingCount,
    },
  );
}

@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectTabsModule,
  ],
  declarations: [
    TestingTabComponent,
  ],
  exports: [
    TestingTabComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class PluginModule {
  constructor() {
    initializeTestManagementPlugin(inject(Injector));
  }
}
