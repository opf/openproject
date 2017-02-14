import {States} from '../../../states.service';
import {
  TimelineCellBuilder,
  timelineCellClassName,
  timelineCollapsedClassName
} from '../../builders/timeline-cell-builder';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WPTableRowSelectionState} from '../../wp-table.interfaces';
import {WorkPackageTable} from '../../wp-fast-table';

export class TimelineTransformer {
  public states:States;
  public timelineCellBuilder = new TimelineCellBuilder();

  constructor(table:WorkPackageTable) {
    injectorBridge(this);

    this.states.table.timelineVisible
      .observeUntil(this.states.table.stopAllSubscriptions).subscribe((visible:boolean) => {
      this.renderVisibility(visible);
    });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderVisibility(visible) {
    jQuery(`.${timelineCellClassName}`).toggleClass(timelineCollapsedClassName, !visible);
  }
}

TimelineTransformer.$inject = ['states'];
