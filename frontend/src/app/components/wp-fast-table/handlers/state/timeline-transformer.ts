import {Injector} from '@angular/core';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableTimelineState} from '../../wp-table-timeline';
import {TableState} from 'core-components/wp-table/table-state/table-state';

export class TimelineTransformer {

  public tableState:TableState = this.injector.get(TableState);

  constructor(private readonly injector:Injector,
              private readonly table:WorkPackageTable) {

   this.tableState.timeline.values$()
      .pipe(
        takeUntil(this.tableState.stopAllSubscriptions)
      )
      .subscribe((state:WorkPackageTableTimelineState) => {
        this.renderVisibility(state.isVisible);
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
