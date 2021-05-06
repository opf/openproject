import { Injectable } from '@angular/core';
import { HookService } from "core-app/modules/plugins/hook-service";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { Tab } from "core-components/wp-tabs/components/wp-tab-wrapper/tab";

@Injectable({
  providedIn: 'root'
})
export class WpTabsService {
  get tabs() {
    return this.hookService.getWorkPackageTabs();
  }

  constructor(
    private hookService:HookService,
  ) {
  }

  getDisplayableTabs(workPackage:WorkPackageResource):Tab[] {
    return this.tabs.filter(tab => tab.displayable(workPackage));
  }

  getTab(tabId:string, workPackage:WorkPackageResource):Tab|undefined {
    return this.getDisplayableTabs(workPackage).find(({ identifier: id }) => id === tabId);
  }
}
