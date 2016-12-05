import {TimelineCellRenderer} from './timeline-cell-renderer';
import {RenderInfo, calculatePositionValueForDayCount, timelineElementCssClass} from './../wp-timeline';

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {
  public get type():string {
    return 'milestone';
  }

  public update(element:HTMLDivElement, wp: op.WorkPackage, renderInfo:RenderInfo) {
    // abort if no start or due date
    if (!wp.date) {
      return;
    }

    element.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";
    element.style.width = '1em';

    const viewParams = renderInfo.viewParams;
    const date = moment(wp.date as any);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, "days");
    element.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);
  }

  /**
   * Render a milestone element, a single day event with no resize, but
   * move functionality.
   */
  public render(renderInfo: RenderInfo):HTMLDivElement {
    const el = document.createElement("div");

    el.className = timelineElementCssClass + " " + this.type;
    el.style.position = "relative";
    el.style.height = "1em";
    el.style.backgroundColor = "red";
    el.style.borderRadius = "2px";
    el.style.zIndex = "50";
    el.style.cursor = "ew-resize";
    el.style.transform = 'rotate(45deg)';
    el.style.transformOrigin = '75% 100%';

    return el;
  }
}