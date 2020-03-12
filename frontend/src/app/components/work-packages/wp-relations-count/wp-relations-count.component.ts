import {Component, Input, OnInit} from '@angular/core';
import {WorkPackageRelationsService} from '../../wp-relations/wp-relations.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {combineLatest} from 'rxjs';
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-relations-count',
})
export class WorkPackageRelationsCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input('wpId') wpId:string;
  public count:number = 0;

  constructor(protected wpCacheService:WorkPackageCacheService,
              protected wpRelations:WorkPackageRelationsService) {
    super();
  }

  ngOnInit():void {
    this.wpRelations.require(this.wpId.toString());

    combineLatest(
      this.wpRelations.state(this.wpId.toString()).values$(),
      this.wpCacheService.loadWorkPackage(this.wpId.toString()).values$()
    ).pipe(
      this.untilDestroyed()
    ).subscribe(([relations, workPackage]) => {
      let relationCount = _.size(relations);
      let childrenCount = _.size(workPackage.children);

      this.count = relationCount + childrenCount;
    });
  }
}
