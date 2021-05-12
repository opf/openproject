import { Injectable, Injector } from '@angular/core';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { WpTabDefinition } from "core-components/wp-tabs/components/wp-tab-wrapper/tab";
import { WorkPackageActivityTabComponent } from "core-components/wp-single-view-tabs/activity-panel/activity-tab.component";
import { WorkPackageRelationsTabComponent } from "core-components/wp-single-view-tabs/relations-tab/relations-tab.component";
import { WorkPackageWatchersTabComponent } from "core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component";
import { workPackageRelationsCount } from "core-components/wp-tabs/services/wp-tabs/wp-relations-count.function";
import { workPackageWatchersCount } from "core-components/wp-tabs/services/wp-tabs/wp-watchers-count.function";
import { StateService } from "@uirouter/angular";
import { WorkPackageOverviewTabComponent } from "core-components/wp-single-view-tabs/overview-tab/overview-tab.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { TabDefinition } from "core-app/modules/common/tabs/tab.interface";

@Injectable({
  providedIn: 'root',
})
export class WorkPackageTabsService {
  private registeredTabs:WpTabDefinition[];

  constructor(
    private $state:StateService,
    private I18n:I18nService,
    private injector:Injector,
  ) {
    this.registeredTabs = this.buildDefaultTabs();
  }

  get tabs():WpTabDefinition[] {
    return [...this.registeredTabs];
  }

  register(...tabs:WpTabDefinition[]) {
    this.registeredTabs = [
      ...this.registeredTabs,
      ...tabs,
    ];
  }

  getDisplayableTabs(workPackage:WorkPackageResource):WpTabDefinition[] {
    return this
      .tabs
      .filter(
        tab => !tab.displayable || tab.displayable(workPackage, this.$state),
      )
      .map(
        tab => ({
          ...tab,
          ...!!tab.count && { counter: tab.count(workPackage, this.injector) },
        }),
      );
  }

  getTab(tabId:string, workPackage:WorkPackageResource):WpTabDefinition|undefined {
    return this.getDisplayableTabs(workPackage).find(({ id: id }) => id === tabId);
  }

  private buildDefaultTabs():WpTabDefinition[] {
    return [
      {
        component: WorkPackageOverviewTabComponent,
        name: this.I18n.t('js.work_packages.tabs.overview'),
        id: 'overview',
        displayable: (_, $state) => $state.includes('**.details.*'),
      },
      {
        id: 'activity',
        component: WorkPackageActivityTabComponent,
        name: I18n.t('js.work_packages.tabs.activity'),
      },
      {
        id: 'relations',
        component: WorkPackageRelationsTabComponent,
        name: I18n.t('js.work_packages.tabs.relations'),
        count: workPackageRelationsCount,
      },
      {
        id: 'watchers',
        component: WorkPackageWatchersTabComponent,
        name: I18n.t('js.work_packages.tabs.watchers'),
        displayable: (workPackage) => !!workPackage.watchers,
        count: workPackageWatchersCount,
      },
    ];
  }
}
