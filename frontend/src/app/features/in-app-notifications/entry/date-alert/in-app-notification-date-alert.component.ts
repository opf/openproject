import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  Input,
} from '@angular/core';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import { Observable } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

@Component({
  selector: 'op-in-app-notification-date-alert',
  templateUrl: './in-app-notification-date-alert.component.html',
  styleUrls: ['./in-app-notification-date-alert.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InAppNotificationDateAlertComponent implements OnInit {
  @Input() aggregatedNotifications:INotification[];

  @Input() notification:INotification;

  @Input() workPackage:WorkPackageResource;

  text = {
    and: this.I18n.t('js.notifications.center.label_actor_and'),
    and_other_singular: this.I18n.t('js.notifications.center.and_more_users.one'),
    and_other_plural: (count:number):string => this.I18n.t('js.notifications.center.and_more_users.other',
      { count }),
    loading: this.I18n.t('js.ajax.loading'),
    placeholder: this.I18n.t('js.placeholders.default'),
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
    updated_by_at: (age:string):string => this.I18n.t('js.notifications.center.text_update_date',
      { date: age }),
  };

  constructor(
    private I18n:I18nService,
    private timezoneService:TimezoneService,
    private deviceService:DeviceService,
    private schemaCache:SchemaCacheService,
  ) { }

  ngOnInit():void {
    this.buildAlertText();
  }

  private buildAlertText() {
    if (this.isOverdue) {
      return;
    }

    if (this.isMilestone) {

    }
  }

  private get isOverdue():boolean {
    return false;
  }

  private get isMilestone():boolean {
    return this.schemaCache.of(this.workPackage).isMilestone as boolean;
  }
}
