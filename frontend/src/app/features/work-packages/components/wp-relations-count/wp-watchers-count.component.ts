import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageWatchersService } from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-watchers-count',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageWatchersCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input('wpId') wpId:string;

  public count = 0;

  constructor(protected apiV3Service:ApiV3Service,
    protected wpWatcherService:WorkPackageWatchersService,
    protected cdRef:ChangeDetectorRef) {
    super();
  }

  ngOnInit():void {
    this
      .apiV3Service
      .work_packages
      .id(this.wpId)
      .requireAndStream()
      .pipe(
        this.untilDestroyed(),
      ).subscribe((workPackage) => {
        this.wpWatcherService
          .require(workPackage)
          .then((watchers:HalResource[]) => {
            this.count = watchers.length;
            this.cdRef.detectChanges();
          });
      });
  }
}
