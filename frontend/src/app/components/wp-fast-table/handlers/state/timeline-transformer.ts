import {Injector} from '@angular/core';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {WorkPackageTimelineState} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-table-timeline";

export class TimelineTransformer {

  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  public wpTableTimeline = this.injector.get(WorkPackageViewTimelineService);

  constructor(private readonly injector:Injector,
              private readonly table:WorkPackageTable) {

    this.wpTableTimeline
      .live$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe((state:WorkPackageTimelineState) => {
        this.renderVisibility(state.visible);
      });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderVisibility(visible:boolean) {
    const container = jQuery(this.table.tableAndTimelineContainer).parent();
    container.find('.work-packages-tabletimeline--timeline-side').toggle(visible);
    container.find('.work-packages-tabletimeline--table-side').toggleClass('-timeline-visible', visible);
  }
}
