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
      .map((tab) => ({
        ...tab,
        route: `${this.uiSrefBase}.tabs`,
        routeParams: { workPackageId: this.workPackage.id, tabIdentifier: tab.id },
      }));
  }

  public switchToFullscreen():void {
    this.keepTab.goCurrentShowState();
  }

  public close():void {
    this.$state.go(
      this.uiRouterGlobals.current.data.baseRoute,
      this.uiRouterGlobals.params,
    );
  }
}
