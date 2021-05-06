import { Component, Input, OnInit } from '@angular/core';
import { combineLatest } from 'rxjs';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { WorkPackageRelationsService } from "core-components/wp-relations/wp-relations.service";

@Component({
  templateUrl: './tab-count.html',
  selector: 'op-wp-relations-count',
})
export class WorkPackageRelationsCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input('wpId') wpId:string;
  public count = 0;

  constructor(protected apiV3Service:APIV3Service,
              protected wpRelations:WorkPackageRelationsService) {
    super();
  }

  ngOnInit():void {
    this.wpRelations.require(this.wpId.toString());

    combineLatest([
      this
        .wpRelations
        .state(this.wpId.toString())
        .values$(),
      this
        .apiV3Service
        .work_packages
        .id(this.wpId)
        .requireAndStream()
    ]).pipe(
      this.untilDestroyed()
    ).subscribe(([relations, workPackage]) => {
      const relationCount = _.size(relations);
      const childrenCount = _.size(workPackage.children);

      this.count = relationCount + childrenCount;
    });
  }
}
