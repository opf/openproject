import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { WpTabsComponent } from './components/wp-tabs/wp-tabs.component';
import {UIRouterModule} from "@uirouter/angular";
import {WpTabWrapperComponent} from "core-app/features/work_packages/components/wp-tabs/components/wp-tab-wrapper/wp-tab-wrapper.component";
import {DynamicModule} from "ng-dynamic-component";
import { OpenprojectAccessibilityModule } from "core-app/shared/directives/a11y/openproject-a11y.module";
import { OpenprojectTabsModule } from "core-app/shared/components/tabs/openproject-tabs.module";
import { IconModule } from "core-app/shared/components/icon/icon.module";

@NgModule({
  declarations: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ],
  imports: [
    CommonModule,
    UIRouterModule,
    DynamicModule,
    OpenprojectAccessibilityModule,
    OpenprojectTabsModule,
    IconModule
  ],
  exports: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ],
})
export class OpWpTabsModule {
}
