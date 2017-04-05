import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {States} from "../../../states.service";
import {timelineCellClassName, timelineCollapsedClassName} from "../../builders/timeline-cell-builder";
import {WorkPackageTable} from "../../wp-fast-table";

export class TimelineTransformer {
  public states:States;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);

    this.states.table.timelineVisible.values$()
      .takeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((visible: boolean) => {
        this.renderVisibility(visible);
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
