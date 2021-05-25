import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { WpTabsComponent } from './components/wp-tabs/wp-tabs.component';
import {UIRouterModule} from "@uirouter/angular";
import {WpTabWrapperComponent} from "core-app/features/work_packages/components/wp-tabs/components/wp-tab-wrapper/wp-tab-wrapper.component";
import {DynamicModule} from "ng-dynamic-component";

@NgModule({
  declarations: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ],
  imports: [
    CommonModule,
    UIRouterModule,
    DynamicModule,
  ],
  exports: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ]
})
export class OpWpTabsModule { }
