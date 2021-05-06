import { ChangeDetectionStrategy, Component, Injector, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { WorkPackageTabsService } from "core-components/wp-tabs/services/wp-tabs/wp-tabs.service";
import { Tab, TabInstance } from "core-app/components/wp-tabs/components/wp-tab-wrapper/tab";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { StateService } from "@uirouter/angular";
import { KeepTabService } from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";
import { UIRouterGlobals } from "@uirouter/core";
import { AngularTrackingHelpers } from "core-components/angular/tracking-functions";

@Component({
  selector: 'op-wp-tabs',
  templateUrl: './wp-tabs.component.html',
  styleUrls: ['./wp-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpTabsComponent implements OnInit {
  @Input() workPackage:WorkPackageResource;
  @Input() view:'full'|'split';

  trackByIdentifier = AngularTrackingHelpers.trackByProperty('identifier');

  public tabs:TabInstance[];
  public uiSrefBase:string;
  public canViewWatchers = false;

  text = {
    tabs: {
      overview: this.I18n.t('js.work_packages.tabs.overview'),
      activity: this.I18n.t('js.work_packages.tabs.activity'),
      relations: this.I18n.t('js.work_packages.tabs.relations'),
      watchers: this.I18n.t('js.work_packages.tabs.watchers')
    },
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
    this.tabs = this.wpTabsService.getDisplayableTabs(this.workPackage);
    this.uiSrefBase = this.view === 'split' ? '' : 'work-packages.show';
    this.canViewWatchers = !!(this.workPackage && this.workPackage.watchers);
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
