import {Component, Input, OnInit} from '@angular/core';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-watchers-count',
})
export class WorkPackageWatchersCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input('wpId') wpId:string;
  public count:number = 0;

  constructor(protected wpCacheService:WorkPackageCacheService) {
    super();
  }

  ngOnInit():void {
    this.wpCacheService.loadWorkPackage(this.wpId.toString()).values$()
      .pipe(
        this.untilDestroyed()
      ).subscribe((workPackage) => {
      this.count = _.size(workPackage.watchers.elements);
    });
  }
}
