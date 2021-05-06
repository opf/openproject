import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { WpTabsComponent } from './components/wp-tabs/wp-tabs.component';
import {UIRouterModule} from "@uirouter/angular";
import {WpTabWrapperComponent} from "core-components/wp-tabs/components/wp-tab-wrapper/wp-tab-wrapper.component";
import {DynamicModule} from "ng-dynamic-component";
import { WorkPackageRelationsCountComponent } from "core-components/wp-tabs/components/tab-badges/wp-relations-count.component";
import { WorkPackageWatchersCountComponent } from "core-components/wp-tabs/components/tab-badges/wp-watchers-count.component";
import { OpenprojectAccessibilityModule } from "core-app/modules/a11y/openproject-a11y.module";

@NgModule({
  declarations: [
    WpTabsComponent,
    WpTabWrapperComponent,
    WorkPackageRelationsCountComponent,
    WorkPackageWatchersCountComponent,
  ],
  imports: [
    CommonModule,
    UIRouterModule,
    DynamicModule,
    OpenprojectAccessibilityModule,
  ],
  exports: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ]
})
export class OpWpTabsModule { }
