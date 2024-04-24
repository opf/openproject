import {
  ApplicationRef,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ComponentFactoryResolver,
  ElementRef,
  Inject,
  InjectionToken,
  Injector,
  OnDestroy,
  OnInit,
  Optional,
  ViewChild,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  ActiveTabInterface,
  TabComponent,
  TabInterface,
  TabPortalOutlet,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ComponentType } from '@angular/cdk/portal';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import { WpGraphConfiguration } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';

export const WpTableConfigurationModalPrependToken = new InjectionToken<ComponentType<any>>('WpTableConfigurationModalPrependComponent');

@Component({
  templateUrl: '../../../../features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpGraphConfigurationModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  public $element:HTMLElement;

  public text = {
    title: this.I18n.t('js.chart.modal_title'),
    closePopup: this.I18n.t('js.close_popup_title'),

    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),
  };

  public configuration:WpGraphConfiguration;

  // Get the view child we'll use as the portal host
  @ViewChild('tabContentOutlet', { static: true }) tabContentOutlet:ElementRef;

  // And a reference to the actual portal host interface
  public tabPortalHost:TabPortalOutlet;

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    @Optional() @Inject(WpTableConfigurationModalPrependToken) public prependModalComponent:ComponentType<any>|null,
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly appRef:ApplicationRef,
    readonly componentFactoryResolver:ComponentFactoryResolver,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly notificationService:WorkPackageNotificationService,
    readonly cdRef:ChangeDetectorRef,
    readonly configurationService:ConfigurationService,
    readonly elementRef:ElementRef,
    readonly graphConfiguration:WpGraphConfigurationService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    this.$element = this.elementRef.nativeElement as HTMLElement;

    this.loadingIndicator.indicator('modal').promise = this.graphConfiguration.loadForms()
      .then(() => {
        this.tabPortalHost = new TabPortalOutlet(
          this.graphConfiguration.tabs,
          this.tabContentOutlet.nativeElement,
          this.componentFactoryResolver,
          this.appRef,
          this.injector,
        );

        const initialTabName = this.locals.initialTab;
        const initialTab = this.availableTabs.find((el) => el.id === initialTabName);
        this.cdRef.markForCheck();
        this.switchTo(initialTab || this.availableTabs[0]);
      });
  }

  ngOnDestroy():void {
    this.tabPortalHost.dispose();
  }

  public get availableTabs():TabInterface[] {
    return this.tabPortalHost.availableTabs;
  }

  public get currentTab():ActiveTabInterface|null {
    return this.tabPortalHost.currentTab;
  }

  public switchTo(tab:TabInterface):void {
    this.tabPortalHost.switchTo(tab);
  }

  public saveChanges():void {
    this.tabPortalHost.activeComponents.forEach((component:TabComponent) => {
      component.onSave();
    });

    this.configuration = this.graphConfiguration.configuration;

    this.service.close();
  }

  /**
   * Called when the user attempts to close the modal window.
   * The service will close this modal if this method returns true
   * @returns {boolean}
   */
  public onClose():boolean {
    this.afterFocusOn.focus();
    return true;
  }

  protected get afterFocusOn():HTMLElement {
    return this.$element;
  }
}
