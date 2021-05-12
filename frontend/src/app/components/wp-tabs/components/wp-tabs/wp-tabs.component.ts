import { ChangeDetectionStrategy, Component, Injector, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { WorkPackageTabsService } from "core-components/wp-tabs/services/wp-tabs/wp-tabs.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { StateService } from "@uirouter/angular";
import { KeepTabService } from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";
import { UIRouterGlobals } from "@uirouter/core";
import { AngularTrackingHelpers } from "core-components/angular/tracking-functions";
import { TabDefinition } from "core-app/modules/common/tabs/tab.interface";

@Component({
  selector: 'op-wp-tabs',
  templateUrl: './wp-tabs.component.html',
  styleUrls: ['./wp-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpTabsComponent implements OnInit {
  @Input() workPackage:WorkPackageResource;
  @Input() view:'full'|'split';

  public tabs:TabDefinition[];
  public uiSrefBase:string;
  public canViewWatchers = false;

  text = {
    details: {
      close: this.I18n.t('js.button_close_details'),
      goToFullScreen: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen'),
    },
  };

  constructor(
    readonly wpTabsService:WorkPackageTabsService,
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly $state:StateService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly keepTab:KeepTabService,
  ) {
  }

  ngOnInit():void {
    this.uiSrefBase = this.view === 'split' ? '' : 'work-packages.show';
    this.canViewWatchers = !!(this.workPackage && this.workPackage.watchers);
    this.tabs = this.getDisplayableTabs();
  }

  private getDisplayableTabs() {
    return this
      .wpTabsService
      .getDisplayableTabs(this.workPackage)
      .map(tab => {
        return {
          ...tab,
          route: this.uiSrefBase + '.tabs',
          routeParams: { workPackageId: this.workPackage.id, tabIdentifier: tab.id }
        };
      });
  }

  public switchToFullscreen():void {
    this.keepTab.goCurrentShowState();
  }

  public close():void {
    this.$state.go(
      this.uiRouterGlobals.current.data.baseRoute,
      this.uiRouterGlobals.params
    );
  }
}
