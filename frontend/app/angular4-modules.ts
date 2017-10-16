import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {UpgradeModule} from '@angular/upgrade/static';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';

@NgModule({
  imports: [
    BrowserModule,
    UpgradeModule
  ],
  providers: [],
  declarations: [
    WorkPackageTimelineHeaderController
  ],
  entryComponents: [
    WorkPackageTimelineHeaderController
  ]
})
export class OpenProjectModule {
  constructor(private upgrade:UpgradeModule) {
  }

  ngDoBootstrap() {
    this.upgrade.bootstrap(document.body, ['openproject'], {strictDi: false});
  }
}


setTimeout(function() {
  platformBrowserDynamic().bootstrapModule(OpenProjectModule);
}, 0);
