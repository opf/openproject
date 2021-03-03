import {
  ApplicationRef,
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
  ViewChild
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/modules/modal/modal.types';
import { OpModalComponent } from 'core-app/modules/modal/modal.component';
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import {
  ActiveTabInterface,
  TabComponent,
  TabInterface,
  TabPortalOutlet
} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import { LoadingIndicatorService } from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { ComponentType } from "@angular/cdk/portal";
import { WpGraphConfigurationService } from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration.service";
import { WpGraphConfiguration } from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Component({
  templateUrl: './time-entries-current-user-configuration.modal.html',
})
export class TimeEntriesCurrentUserConfigurationModalComponent extends OpModalComponent implements OnInit  {

  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public $element:JQuery;

  public text = {
    displayedDays: this.I18n.t('js.grid.widgets.time_entries_current_user.displayed_days'),
    closePopup: this.I18n.t('js.close_popup_title'),

    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),

    weekdays: moment.weekdays()
  };

  public firstDayOfWeek:number;
  public firstDayOffset = this.configuration.startOfWeek();

  // All days of the week, zero based on Monday.
  public options:{ days:boolean[] };
  public days:boolean[];

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly injector:Injector,
              readonly appRef:ApplicationRef,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly notificationService:WorkPackageNotificationService,
              readonly cdRef:ChangeDetectorRef,
              readonly configuration:ConfigurationService,
              readonly elementRef:ElementRef) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    this.days = this.locals.options.days || Array.from({ length: 7 }, () => true );

    const momentFirstDayOffset = 1 + moment.localeData().firstDayOfWeek() % 7;
    this.text.weekdays = moment.localeData().weekdays().slice(momentFirstDayOffset).concat(moment.localeData().weekdays().slice(0, momentFirstDayOffset));
  }

  public saveChanges():void {
    this.options = { days: this.days };
    this.service.close();
  }
}
