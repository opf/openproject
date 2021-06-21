import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  ComponentFactoryResolver,
  ElementRef,
  Injector,
  OnInit,
  ViewChild,
} from '@angular/core';
import {
  TabComponent,
  TabInterface,
  TabPortalOutlet,
} from "core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet";
import { I18nService } from "core-app/core/i18n/i18n.service";
import { FormControl, FormGroup } from "@angular/forms";

@Component({
  templateUrl: './my-notifications-page.component.html',
  styleUrls: ['./my-notifications-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyNotificationsPageComponent implements OnInit {

  text = {
    save: this.I18n.t('js.button_save'),
    enable: this.I18n.t('js.notifications.settings.enable_app_notifications'),
    email: this.I18n.t('js.notifications.email'),
    inApp: this.I18n.t('js.notifications.in_app'),
  };

  form = new FormGroup({
    enabled: new FormControl(''),
  });

  get enabledControl() {
    return this.form.get('enabled');
  }

  tabPortalHost:TabPortalOutlet;
  @ViewChild('tabContentOutlet', { static: true }) tabContentOutlet:ElementRef;

  constructor(
    private I18n:I18nService
  ) {
  }

  ngOnInit():void {
  }

  public saveChanges():void {
    this.submit();
  }

  private submit():void {
  }
}
