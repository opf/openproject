import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageRelationsService} from '../../wp-relations/wp-relations.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {combineLatest} from 'rxjs';

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-relations-count',
})
export class WorkPackageRelationsCountComponent implements OnInit, OnDestroy {
  @Input('wpId') wpId:string;
  public count:number = 0;

  constructor(protected wpCacheService:WorkPackageCacheService,
              protected wpRelations:WorkPackageRelationsService) {
  }

  ngOnInit():void {
    this.wpRelations.require(this.wpId.toString());

    combineLatest(
      this.wpRelations.state(this.wpId.toString()).values$(),
      this.wpCacheService.loadWorkPackage(this.wpId.toString()).values$()
    ).pipe(
      takeUntil(componentDestroyed(this))
    ).subscribe(([relations, workPackage]) => {
      let relationCount = _.size(relations);
      let childrenCount = _.size(workPackage.children);

      this.count = relationCount + childrenCount;
    });
}

  ngOnDestroy():void {
    // Nothing to do
  }
}
