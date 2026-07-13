import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { combineLatest } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-relations-count',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WorkPackageRelationsCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input() wpId:string;

  public count = 0;

  constructor(protected apiV3Service:ApiV3Service,
    protected wpRelations:WorkPackageRelationsService,
    protected cdRef:ChangeDetectorRef) {
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
        .requireAndStream(),
    ]).pipe(
      this.untilDestroyed(),
    ).subscribe(([relations, workPackage]) => {
      const relationCount = Object.keys(relations).length;
      const childrenCount = (workPackage.children ?? []).length;

      this.count = relationCount + childrenCount;
      this.cdRef.markForCheck();
    });
  }
}
