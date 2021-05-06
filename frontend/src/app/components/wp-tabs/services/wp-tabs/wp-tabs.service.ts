import { Injectable, Injector } from '@angular/core';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { Tab, TabDefinition, TabInstance } from "core-components/wp-tabs/components/wp-tab-wrapper/tab";
import { WorkPackageActivityTabComponent } from "core-components/wp-single-view-tabs/activity-panel/activity-tab.component";
import { WorkPackageRelationsTabComponent } from "core-components/wp-single-view-tabs/relations-tab/relations-tab.component";
import { WorkPackageWatchersTabComponent } from "core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component";
import { workPackageRelationsCount } from "core-components/wp-tabs/services/wp-tabs/wp-relations-count.function";
import { workPackageWatchersCount } from "core-components/wp-tabs/services/wp-tabs/wp-watchers-count.function";
import { StateService } from "@uirouter/angular";
import { WorkPackageOverviewTabComponent } from "core-components/wp-single-view-tabs/overview-tab/overview-tab.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

@Injectable({
  providedIn: 'root',
})
export class WorkPackageTabsService {
  private registeredTabs:TabDefinition[];

  constructor(
    private $state:StateService,
    private I18n:I18nService,
    private injector:Injector,
  ) {
    this.registeredTabs = this.buildDefaultTabs();
  }

  get tabs() {
    return [...this.registeredTabs];
  }

  register(...tabs:TabDefinition[]) {
    this.registeredTabs = [
      ...this.registeredTabs,
      ...tabs,
    ];
  }

  getDisplayableTabs(workPackage:WorkPackageResource):TabInstance[] {
    return this
      .tabs
      .filter(
        tab => !tab.displayable || tab.displayable(workPackage, this.$state),
      )
      .map(
        tab => ({
          ...tab,
          counter: tab.count && tab.count(workPackage, this.injector),
        }),
      );
  }

  getTab(tabId:string, workPackage:WorkPackageResource):Tab|undefined {
    return this.getDisplayableTabs(workPackage).find(({ identifier: id }) => id === tabId);
  }

  private buildDefaultTabs():TabDefinition[] {
    return [
      {
        component: WorkPackageOverviewTabComponent,
        name: this.I18n.t('js.work_packages.tabs.overview'),
        identifier: 'overview',
        displayable: (_, $state) => $state.includes('**.details.*'),
      },
      {
        identifier: 'activity',
        component: WorkPackageActivityTabComponent,
        name: I18n.t('js.work_packages.tabs.activity'),
      },
      {
        identifier: 'relations',
        component: WorkPackageRelationsTabComponent,
        name: I18n.t('js.work_packages.tabs.relations'),
        count: workPackageRelationsCount,
      },
      {
        identifier: 'watchers',
        component: WorkPackageWatchersTabComponent,
        name: I18n.t('js.work_packages.tabs.watchers'),
        displayable: (workPackage) => !!workPackage.watchers,
        count: workPackageWatchersCount,
      },
    ];
  }
}
