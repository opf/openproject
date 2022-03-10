import { Injectable, Injector } from '@angular/core';
import { from } from 'rxjs';
import { StateService } from '@uirouter/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WpTabDefinition } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import { WorkPackageRelationsTabComponent } from 'core-app/features/work-packages/components/wp-single-view-tabs/relations-tab/relations-tab.component';
import { WorkPackageOverviewTabComponent } from 'core-app/features/work-packages/components/wp-single-view-tabs/overview-tab/overview-tab.component';
import { WorkPackageActivityTabComponent } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-tab.component';
import { WorkPackageWatchersTabComponent } from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { workPackageWatchersCount } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-watchers-count.function';
import { workPackageRelationsCount } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-relations-count.function';
import { workPackageNotificationsCount } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-notifications-count.function';

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
        (tab) => !tab.displayable || tab.displayable(workPackage, this.$state),
      )
      .map(
        (tab) => ({
          ...tab,
          counter: tab.count
            ? (injector:Injector) => tab.count!(workPackage, injector || this.injector) // eslint-disable-line @typescript-eslint/no-non-null-assertion
            : (_:Injector) => from([0]), // eslint-disable-line @typescript-eslint/no-unused-vars
        }),
      );
  }

  getTab(tabId:string, workPackage:WorkPackageResource):WpTabDefinition|undefined {
    return this.getDisplayableTabs(workPackage).find(({ id }) => id === tabId);
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
        count: workPackageNotificationsCount,
        showCountAsBubble: true,
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
