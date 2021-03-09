import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { WorkPackageWatchersService } from 'core-app/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-watchers-count',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WorkPackageWatchersCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input('wpId') wpId:string;
  public count = 0;

  constructor(protected apiV3Service:APIV3Service,
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
        this.untilDestroyed()
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
