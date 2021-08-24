import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import { WpTabWrapperComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/wp-tab-wrapper.component';
import { DynamicModule } from 'ng-dynamic-component';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { WpTabsComponent } from './components/wp-tabs/wp-tabs.component';

@NgModule({
  declarations: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ],
  imports: [
    CommonModule,
    UIRouterModule,
    DynamicModule,
    OpenprojectTabsModule,
    IconModule,
  ],
  exports: [
    WpTabsComponent,
    WpTabWrapperComponent,
  ],
})
export class OpWpTabsModule {
}
