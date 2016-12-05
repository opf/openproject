import {RenderInfo, calculatePositionValueForDayCount, timelineElementCssClass} from './../wp-timeline';

const classNameLeftHandle = "leftHandle";
const classNameRightHandle = "rightHandle";

export class TimelineCellRenderer {

  public get type():string {
    return 'bar';
  }

  public update(element:HTMLDivElement, wp: op.WorkPackage, renderInfo:RenderInfo) {
    // abort if no start or due date
    if (!wp.startDate || !wp.dueDate) {
      return;
    }

    // general settings - bar
    element.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";

    const viewParams = renderInfo.viewParams;
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);

    // offset left
    const offsetStart = start.diff(viewParams.dateDisplayStart, "days");
    element.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);

    // duration
    const duration = due.diff(start, "days") + 1;
    element.style.width = calculatePositionValueForDayCount(viewParams, duration);
  }

  /**
   * Render the generic cell element, a bar spanning from
   * start to due date.
   */
  public render(renderInfo:RenderInfo):HTMLDivElement {
    const bar = document.createElement("div");

    bar.className = timelineElementCssClass + " " + this.type;
    bar.style.position = "relative";
    bar.style.height = "1em";
    bar.style.backgroundColor = "#8CD1E8";
    bar.style.borderRadius = "2px";
    bar.style.cssFloat = "left";
    bar.style.zIndex = "50";
    bar.style.cursor = "ew-resize";

    const left = document.createElement("div");
    left.className = classNameLeftHandle;
    left.style.position = "absolute";
    left.style.backgroundColor = "red";
    left.style.left = "0px";
    left.style.top = "0px";
    left.style.width = "20px";
    left.style.maxWidth = "20%";
    left.style.height = "100%";
    left.style.cursor = "w-resize";
    bar.appendChild(left);

    const right = document.createElement("div");
    right.className = classNameRightHandle;
    right.style.position = "absolute";
    right.style.backgroundColor = "green";
    right.style.right = "0px";
    right.style.top = "0px";
    right.style.width = "20px";
    right.style.maxWidth = "20%";
    right.style.height = "100%";
    right.style.cursor = "e-resize";
    bar.appendChild(right)

    return bar;
  }
}