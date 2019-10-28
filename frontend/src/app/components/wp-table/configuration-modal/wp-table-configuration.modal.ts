import {
  ApplicationRef,
  ChangeDetectorRef,
  Component,
  ComponentFactoryResolver,
  ElementRef,
  EventEmitter,
  Inject,
  InjectionToken,
  Injector,
  OnDestroy,
  OnInit,
  Optional,
  ViewChild
} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {WorkPackageViewColumnsService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {WpTableConfigurationService} from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import {
  ActiveTabInterface,
  TabComponent,
  TabInterface,
  TabPortalOutlet
} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {QueryFormDmService} from 'core-app/modules/hal/dm-services/query-form-dm.service';
import {WorkPackageStatesInitializationService} from 'core-components/wp-list/wp-states-initialization.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {ComponentType} from "@angular/cdk/portal";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

export const WpTableConfigurationModalPrependToken = new InjectionToken<ComponentType<any>>('WpTableConfigurationModalPrependComponent');

@Component({
  templateUrl: './wp-table-configuration.modal.html'
})
export class WpTableConfigurationModalComponent extends OpModalComponent implements OnInit, OnDestroy  {

  /* Close on escape? */
  public closeOnEscape = false;

  /* Close on outside click */
  public closeOnOutsideClick = false;

  public $element:JQuery;

  public text = {
    title: this.I18n.t('js.work_packages.table_configuration.modal_title'),
    closePopup: this.I18n.t('js.close_popup_title'),

    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),
    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),

    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link')
  };

  public onDataUpdated = new EventEmitter<void>();
  public selectedColumnMap:{ [id:string]:boolean } = {};

  // Get the view child we'll use as the portal host
  @ViewChild('tabContentOutlet', { static: true }) tabContentOutlet:ElementRef;
  // And a reference to the actual portal host interface
  public tabPortalHost:TabPortalOutlet;

  // Try to load an optional provided configuration service, and fall back to the default one
  private wpTableConfigurationService:WpTableConfigurationService =
    this.injector.get(WpTableConfigurationService, new WpTableConfigurationService(this.I18n));

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              @Optional() @Inject(WpTableConfigurationModalPrependToken) public prependModalComponent:ComponentType<any>|null,
              readonly I18n:I18nService,
              readonly injector:Injector,
              readonly appRef:ApplicationRef,
              readonly componentFactoryResolver:ComponentFactoryResolver,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly querySpace:IsolatedQuerySpace,
              readonly queryFormDm:QueryFormDmService,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly notificationService:WorkPackageNotificationService,
              readonly wpTableColumns:WorkPackageViewColumnsService,
              readonly cdRef:ChangeDetectorRef,
              readonly ConfigurationService:ConfigurationService,
              readonly elementRef:ElementRef) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.tabPortalHost = new TabPortalOutlet(
      this.wpTableConfigurationService.tabs,
      this.tabContentOutlet.nativeElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector
    );

    this.loadingIndicator.indicator('modal').promise = this.loadForm()
      .then(() => {
        const initialTab = this.locals['initialTab'] || this.availableTabs[0].name;
        this.switchTo(initialTab);
      });
  }

  ngOnDestroy() {
    this.onDataUpdated.complete();
    this.tabPortalHost.dispose();
  }

  public get availableTabs():TabInterface[] {
    return this.tabPortalHost.availableTabs;
  }

  public get currentTab():ActiveTabInterface|null {
    return this.tabPortalHost.currentTab;
  }

  public switchTo(name:string) {
    this.tabPortalHost.switchTo(name);
  }

  public saveChanges():void {
    this.tabPortalHost.activeComponents.forEach((component:TabComponent) => {
      component.onSave();
    });

    this.onDataUpdated.emit();
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

  protected get afterFocusOn():JQuery {
    return this.$element;
  }

  protected loadForm() {
    const query = this.querySpace.query.value!;
    return this.queryFormDm
      .load(query)
      .then((form:QueryFormResource) => {
          this.wpStatesInitialization.updateStatesFromForm(query, form);

          return form;
        })
      .catch((error) => this.notificationService.handleRawError(error));
  }
}
