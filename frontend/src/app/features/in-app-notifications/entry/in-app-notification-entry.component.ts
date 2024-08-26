import { ChangeDetectionStrategy, Component, HostBinding, Input, OnInit, ViewEncapsulation } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Observable } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';

@Component({
  selector: 'op-in-app-notification-entry',
  templateUrl: './in-app-notification-entry.component.html',
  styleUrls: ['./in-app-notification-entry.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class InAppNotificationEntryComponent implements OnInit {
  @HostBinding('class.op-ian-item') className = true;

  @Input() notification:INotification;

  @Input() aggregatedNotifications:INotification[];

  workPackage$:Observable<WorkPackageResource>|null = null;

  showDateAlert = false;

  loading$ = this.storeService.query.selectLoading();

  // The translated reason, if available
  translatedReasons:{ [reason:string]:number };

  project?:{ href:string, title:string, showUrl:string };

  text = {
    loading: this.I18n.t('js.ajax.loading'),
    placeholder: this.I18n.t('js.placeholders.default'),
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
  };

  private clickTimer:ReturnType<typeof setTimeout>;

  private workPackageId:string|null;

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly storeService:IanCenterService,
    readonly timezoneService:TimezoneService,
    readonly pathHelper:PathHelperService,
    readonly deviceService:DeviceService,
    readonly urlParams:UrlParamsService,
  ) {
  }

  ngOnInit():void {
    const href = this.notification._links.resource?.href;
    this.workPackageId = href && HalResource.matchFromLink(href, 'work_packages');

    this.showDateAlert = this.hasActiveDateAlert();
    this.buildTranslatedReason();
    this.buildProject();
    this.loadWorkPackage();
  }

  private hasActiveDateAlert():boolean {
    if (this.urlParams.get('filter') === 'reason' && this.urlParams.get('name') === 'date_alert') {
      return true;
    }

    const dateAlerts = this.aggregatedNotifications.filter((notification) => notification.reason === 'dateAlert');
    return dateAlerts.length === this.aggregatedNotifications.length;
  }

  private loadWorkPackage() {
    // not a work package reference
    if (this.workPackageId) {
      this.workPackage$ = this
        .apiV3Service
        .work_packages
        .id(this.workPackageId)
        .requireAndStream();
    }
  }

  onClick():void {
    clearTimeout(this.clickTimer); // Clear timer from the any previous single click events.
    this.clickTimer = setTimeout(() => {
      // The single click logic is handled in a timeout, because
      // it needs to be canceled in case the event is a double click.
      this.showDetails();
    }, 250);
  }

  showDetails():void {
    if (!this.workPackageId) {
      return;
    }

    const tab = this.showDateAlert ? 'overview' : 'activity';
    this.storeService.openSplitScreen(this.workPackageId, tab);
  }

  onDoubleClick():void {
    clearTimeout(this.clickTimer); // Clear timer from the single click event onClick.
    this.showFullView();
  }

  showFullView():void {
    const href = this.notification._links.resource?.href;
    const id = href && HalResource.matchFromLink(href, 'work_packages');

    this.storeService.openFullView(id);
  }

  projectClicked(event:MouseEvent):void { // eslint-disable-line class-methods-use-this
    event.stopPropagation();
  }

  markAsRead(event:MouseEvent, notifications:INotification[]):void {
    event.stopPropagation();
    this.storeService.markAsRead(notifications.map((el) => el.id));
  }

  isMobile():boolean {
    return this.deviceService.isMobile;
  }

  private buildTranslatedReason() {
    const reasons:{ [reason:string]:number } = {};

    this
      .aggregatedNotifications
      .forEach((notification) => {
        const translatedReason = this.I18n.t(
          `js.notifications.reasons.${notification.reason}`,
          { defaultValue: notification.reason || this.text.placeholder },
        );

        reasons[translatedReason] = reasons[translatedReason] || 0;
        reasons[translatedReason] += 1;
      });

    this.translatedReasons = reasons;
  }

  private buildProject() {
    const { project } = this.notification._links;

    if (project) {
      this.project = {
        ...project,
        showUrl: this.pathHelper.projectPath(idFromLink(project.href)),
      };
    }
  }
}
