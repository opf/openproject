import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { TabComponent } from "core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet";
import { I18nService } from "core-app/core/i18n/i18n.service";
import { FormControl, FormGroup } from "@angular/forms";

@Component({
  templateUrl: './in-app-notifications-tab.component.html',
  styleUrls: ['./in-app-notifications-tab.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationsTabComponent implements TabComponent, OnInit {

  text = {
    enable: this.I18n.t('js.notifications.settings.enable_app_notifications'),
  };

  form = new FormGroup({
    enabled: new FormControl(''),
  });

  get enabledControl() {
    return this.form.get('enabled');
  }

  constructor(
    private I18n:I18nService,
  ) {
  }

  ngOnInit():void {
  }

  onSave() {

  }
}
