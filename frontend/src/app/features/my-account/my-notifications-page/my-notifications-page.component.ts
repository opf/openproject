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
import { InAppNotificationsTabComponent } from "core-app/features/my-account/my-notifications-page/in-app-notifications-tab/in-app-notifications-tab.component";

@Component({
  templateUrl: './my-notifications-page.component.html',
  styleUrls: ['./my-notifications-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyNotificationsPageComponent implements OnInit {

  text = {
    save: this.I18n.t('js.button_save'),
  };

  tabs:TabInterface[] = [
    {
      id: 'in-app',
      name: this.I18n.t('js.notifications.in_app'),
      componentClass: InAppNotificationsTabComponent,
    },
    {
      id: 'email',
      name: this.I18n.t('js.notifications.email'),
      componentClass: InAppNotificationsTabComponent,
    },
  ];

  tabPortalHost:TabPortalOutlet;
  @ViewChild('tabContentOutlet', { static: true }) tabContentOutlet:ElementRef;

  constructor(
    private I18n:I18nService,
    private componentFactoryResolver:ComponentFactoryResolver,
    private appRef:ApplicationRef,
    private injector:Injector,
  ) {
  }

  ngOnInit():void {
    this.tabPortalHost = new TabPortalOutlet(
      this.tabs,
      this.tabContentOutlet.nativeElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector,
    );

    this.switchTo(this.tabs[0]);
  }

  public switchTo(tab:TabInterface):void {
    this.tabPortalHost.switchTo(tab);
  }

  public saveChanges():void {
    this.tabPortalHost.activeComponents.forEach((component:TabComponent) => {
      component.onSave();
    });

    this.submit();
  }

  private submit():void {
  }
}
