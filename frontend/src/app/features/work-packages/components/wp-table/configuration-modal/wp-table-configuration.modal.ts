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
  ViewChild,
} from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import {
  ActiveTabInterface,
  TabComponent,
  TabInterface,
  TabPortalOutlet,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { ComponentType } from '@angular/cdk/portal';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { StateService } from '@uirouter/angular';

export const WpTableConfigurationModalPrependToken = new InjectionToken<ComponentType<any>>('WpTableConfigurationModalPrependComponent');

@Component({
  templateUrl: './wp-table-configuration.modal.html',
})
export class WpTableConfigurationModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  public text = {
    title: this.I18n.t('js.work_packages.table_configuration.modal_title'),
    closePopup: this.I18n.t('js.close_popup_title'),

    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),
    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),

    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link'),
  };

  public onDataUpdated = new EventEmitter<void>();

  public selectedColumnMap:{ [id:string]:boolean } = {};

  // Get the view child we'll use as the portal host
  @ViewChild('tabContentOutlet', { static: true }) tabContentOutlet:ElementRef;

  // And a reference to the actual portal host interface
  public tabPortalHost:TabPortalOutlet;

  // Try to load an optional provided configuration service, and fall back to the default one
  private wpTableConfigurationService:WpTableConfigurationService =
  this.injector.get(WpTableConfigurationService, new WpTableConfigurationService(this.I18n, this.$state));

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    @Optional() @Inject(WpTableConfigurationModalPrependToken) public prependModalComponent:ComponentType<any>|null,
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly appRef:ApplicationRef,
    readonly componentFactoryResolver:ComponentFactoryResolver,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly querySpace:IsolatedQuerySpace,
    readonly wpStatesInitialization:WorkPackageStatesInitializationService,
    readonly apiV3Service:ApiV3Service,
    readonly notificationService:WorkPackageNotificationService,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly cdRef:ChangeDetectorRef,
    readonly ConfigurationService:ConfigurationService,
    readonly elementRef:ElementRef,
    readonly $state:StateService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    this.$element = this.elementRef.nativeElement as HTMLElement;

    this.tabPortalHost = new TabPortalOutlet(
      this.wpTableConfigurationService.tabs,
      this.tabContentOutlet.nativeElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector,
    );

    this.loadingIndicator.indicator('modal').promise = this.loadForm()
      .then(() => {
        const initialTabName = this.locals.initialTab;
        const initialTab = this.availableTabs.find((el) => el.id === initialTabName);
        this.switchTo(initialTab || this.availableTabs[0]);
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    this.onDataUpdated.complete();
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

  protected get afterFocusOn():HTMLElement {
    return this.$element;
  }

  protected loadForm() {
    const query = this.querySpace.query.value!;
    return this
      .apiV3Service
      .queries
      .form
      .load(query)
      .toPromise()
      .then(([form, _]:[QueryFormResource, QueryResource]) => {
        this.wpStatesInitialization.updateStatesFromForm(query, form);

        return form;
      })
      .catch((error) => this.notificationService.handleRawError(error));
  }
}
