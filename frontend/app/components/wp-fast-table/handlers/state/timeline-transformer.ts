import { WorkPackageTableTimelineVisible } from './../../wp-table-timeline-visible';
import {States} from "../../../states.service";
import {timelineCellClassName, timelineCollapsedClassName} from "../../builders/timeline-cell-builder";
import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTable} from "../../wp-fast-table";

export class TimelineTransformer {
  public states:States;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);

    this.states.table.timelineVisible.values$()
      .takeUntil(this.states.table.stopAllSubscriptions).subscribe((state:WorkPackageTableTimelineVisible) => {
      this.renderVisibility(state.isVisible);
    });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderVisibility(visible:boolean) {
    jQuery(`.${timelineCellClassName}`).toggleClass(timelineCollapsedClassName, !visible);
  }
}

TimelineTransformer.$inject = ['states'];
