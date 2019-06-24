import {Injector} from '@angular/core';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableTimelineState} from '../../wp-table-timeline';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageTableTimelineService} from "core-components/wp-fast-table/state/wp-table-timeline.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

export class TimelineTransformer {

  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  public wpTableTimeline = this.injector.get(WorkPackageTableTimelineService);

  constructor(private readonly injector:Injector,
              private readonly table:WorkPackageTable) {

    this.wpTableTimeline
      .live$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe((state:WorkPackageTableTimelineState) => {
        this.renderVisibility(state.visible);
      });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderVisibility(visible:boolean) {
    const container = jQuery(this.table.container);
    container.find('.work-packages-tabletimeline--timeline-side').toggle(visible);
    container.find('.work-packages-tabletimeline--table-side').toggleClass('-timeline-visible', visible);
  }
}
