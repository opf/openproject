import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {combineLatest} from 'rxjs';

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-watchers-count',
})
export class WorkPackageWatchersCountComponent implements OnInit, OnDestroy {
  @Input('wpId') wpId:string;
  public count:number = 0;

  constructor(protected wpCacheService:WorkPackageCacheService) {
  }

  ngOnInit():void {
    this.wpCacheService.loadWorkPackage(this.wpId.toString()).values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      ).subscribe((workPackage) => {
        this.count =  _.size(workPackage.watchers.elements);
      });
}

  ngOnDestroy():void {
    // Nothing to do
  }
}
