import {Component, Input, OnInit} from '@angular/core';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import { WorkPackageWatchersService } from 'core-app/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-watchers-count',
})
export class WorkPackageWatchersCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input('wpId') wpId:string;
  public count:number = 0;

  constructor(protected wpCacheService:WorkPackageCacheService,
              protected wpWatcherService:WorkPackageWatchersService) {
    super();
  }

  ngOnInit():void {
    this.wpCacheService.loadWorkPackage(this.wpId.toString()).values$()
      .pipe(
        this.untilDestroyed()
      ).subscribe((workPackage) => {
        this.wpWatcherService.require(workPackage)
        .then((watchers:HalResource[]) => {
          this.count = watchers.length;
        });
    });
  }
}
