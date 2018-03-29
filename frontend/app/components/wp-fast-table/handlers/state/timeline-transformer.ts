import {Injector} from '@angular/core';
import {takeUntil} from 'rxjs/operators';
import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableTimelineState} from '../../wp-table-timeline';

export class TimelineTransformer {

  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.states.globalTable.timelineVisible.values$()
      .pipe(
        takeUntil(this.states.globalTable.stopAllSubscriptions)
      )
      .subscribe((state:WorkPackageTableTimelineState) => {
        this.renderVisibility(state.isVisible);
      });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderVisibility(visible:boolean) {
    jQuery('.work-packages-tabletimeline--timeline-side').toggle(visible);
    jQuery('.work-packages-tabletimeline--table-side').toggleClass('-timeline-visible', visible);
  }
}
