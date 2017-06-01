import {States} from "../../../states.service";
import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableTimelineState} from "../../wp-table-timeline";

export class TimelineTransformer {
  public states:States;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);

    this.states.table.timelineVisible.values$()
      .takeUntil(this.states.table.stopAllSubscriptions).subscribe((state:WorkPackageTableTimelineState) => {
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

TimelineTransformer.$inject = ['states'];
