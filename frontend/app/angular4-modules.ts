import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {UpgradeModule} from '@angular/upgrade/static';
import {States} from 'core-components/states.service';
import {WorkPackageRelationsService} from 'core-components/wp-relations/wp-relations.service';
import {TimelineControllerHolder} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import {WorkPackageTableTimelineRelations} from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {WorkPackageTableTimelineStaticElements} from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';

function upgradeService(ng1InjectorName:string, providedType:any) {
  return {
    provide: providedType,
    useFactory: (i:any) => i.get(ng1InjectorName),
    deps: ['$injector']
  };
}

@NgModule({
  imports: [
    BrowserModule,
    UpgradeModule
  ],
  providers: [
    TimelineControllerHolder,
    upgradeService('wpRelations', WorkPackageRelationsService),
    upgradeService('states', States),
  ],
  declarations: [
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements
  ],
  entryComponents: [
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements
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
