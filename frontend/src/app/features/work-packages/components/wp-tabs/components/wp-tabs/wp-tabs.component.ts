import { ChangeDetectionStrategy, Component, Injector, Input, OnInit } from '@angular/core';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { StateService, UIRouterGlobals } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

@Component({
  selector: 'op-wp-tabs',
  templateUrl: './wp-tabs.component.html',
  styleUrls: ['./wp-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpTabsComponent implements OnInit {
  @Input() workPackage:WorkPackageResource;

  @Input() view:'full'|'split';

  @Input() routedFromAngular:boolean = true;

  @Input() public currentTabId:string|null = null;

  public tabs:TabDefinition[];

  public canViewWatchers = false;

  text = {
    details: {
      close: this.I18n.t('js.button_close_details'),
      goToFullScreen: this.I18n.t('js.button_show_fullscreen'),
    },
  };

  constructor(
    readonly wpTabsService:WorkPackageTabsService,
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly $state:StateService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly keepTab:KeepTabService,
    readonly pathHelper:PathHelperService,
    readonly currentProject:CurrentProjectService,
  ) {
  }

  ngOnInit():void {
    this.canViewWatchers = !!(this.workPackage && this.workPackage.watchers);
    this.tabs = this.getDisplayableTabs();
  }

  private getDisplayableTabs() {
    return this
      .wpTabsService
      .getDisplayableTabs(this.workPackage)
      .map((tab) => {
        if (this.routedFromAngular) {
          return ({
              ...tab,
              route: '.tabs',
              routeParams: { workPackageId: this.workPackage.id, tabIdentifier: tab.id },
            });
        }

        return ({
          ...tab,
          path: this.pathHelper.genericWorkPackagePath(this.currentProject.identifier, this.workPackage.id!, tab.id),
        });
      });
  }

  public switchToFullscreen():void {
    this.keepTab.goCurrentShowState(this.workPackage.id!);
  }

  public close():void {
    this.$state.go(
      this.uiRouterGlobals.current.data.baseRoute,
      this.uiRouterGlobals.params,
    );
  }
}
