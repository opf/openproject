import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {UpgradeModule} from '@angular/upgrade/static';
import {States} from 'core-components/states.service';
import {WorkPackageDisplayFieldService} from 'core-components/wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageRelationsService} from 'core-components/wp-relations/wp-relations.service';
import {TimelineControllerHolder} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import {WorkPackageTableTimelineRelations} from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {WorkPackageTableTimelineStaticElements} from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {WorkPackageTableSumsRowController} from 'core-components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import {I18nToken, upgradeService, upgradeServiceWithToken} from './angular4-transition-utils';
import {WorkPackageTableTimelineGrid} from 'core-components/wp-table/timeline/grid/wp-timeline-grid.directive';


@NgModule({
  imports: [
    BrowserModule,
    UpgradeModule
  ],
  providers: [
    TimelineControllerHolder,
    upgradeService('wpRelations', WorkPackageRelationsService),
    upgradeService('states', States),
    upgradeService('wpDisplayField', WorkPackageDisplayFieldService),
    upgradeServiceWithToken('I18n', I18nToken)
  ],
  declarations: [
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements,
    WorkPackageTableSumsRowController,
    WorkPackageTableTimelineGrid
  ],
  entryComponents: [
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements,
    WorkPackageTableTimelineGrid
  ]
})
export class OpenProjectModule {
  constructor(private upgrade:UpgradeModule) {
  }

  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap() {
    this.upgrade.bootstrap(document.body, ['openproject'], {strictDi: false});
  }
}


setTimeout(function() {
  platformBrowserDynamic().bootstrapModule(OpenProjectModule);
}, 0);
