import * as moment from 'moment';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import {
  calculatePositionValueForDayCountingPx,
  RenderInfo,
  timelineElementCssClass
} from '../wp-timeline';
import { CellDateMovement, LabelPosition, TimelineCellRenderer } from './timeline-cell-renderer';
import {
  classNameFarRightLabel,
  classNameHideOnHover,
  classNameHoverStyle,
  classNameLeftHoverLabel,
  classNameLeftLabel,
  classNameRightContainer,
  classNameRightHoverLabel,
  classNameRightLabel,
  classNameShowOnHover,
  WorkPackageCellLabels
} from './wp-timeline-cell';
import Moment = moment.Moment;
import { WorkPackageChangeset } from "core-components/wp-edit/work-package-changeset";

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {
  public get type():string {
    return 'milestone';
  }

  public isEmpty(wp:WorkPackageResource) {
    const date = moment(wp.date as any);
    return _.isNaN(date.valueOf());
  }

  public canMoveDates(wp:WorkPackageResource) {
    const schema = this.schemaCache.of(wp);
    return schema.date.writable && schema.isAttributeEditable('date');
  }

  public displayPlaceholderUnderCursor(ev:MouseEvent, renderInfo:RenderInfo):HTMLElement {
    const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);

    const placeholder = document.createElement('div');
    placeholder.className = 'timeline-element milestone';
    placeholder.style.pointerEvents = 'none';
    placeholder.style.height = '1em';
    placeholder.style.width = '1em';
    placeholder.style.left = (days * renderInfo.viewParams.pixelPerDay) + 'px';

    const diamond = document.createElement('div');
    diamond.className = 'diamond';
    diamond.style.left = '0.5em';
    diamond.style.height = '1em';
    diamond.style.width = '1em';
    placeholder.appendChild(diamond);

    this.applyTypeColor(renderInfo, diamond);

    return placeholder;
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and finish date .
   *
   */
  public assignDateValues(change:WorkPackageChangeset,
    labels:WorkPackageCellLabels,
    dates:any):void {

    this.assignDate(change, 'date', dates.date);
    this.updateLabels(true, labels, change);
  }

  /**
   * Handle movement by <delta> days of milestone.
   */
  public onDaysMoved(change:WorkPackageChangeset,
    dayUnderCursor:Moment,
    delta:number,
    direction:'left' | 'right' | 'both' | 'create' | 'dragright') {

    const initialDate = change.pristineResource.date;
    const dates:CellDateMovement = {};

    if (initialDate) {
      dates.date = moment(initialDate).add(delta, 'days');
    }

    return dates;
  }

  public onMouseDown(ev:MouseEvent,
    dateForCreate:string | null,
    renderInfo:RenderInfo,
    labels:WorkPackageCellLabels,
    elem:HTMLElement):'left' | 'right' | 'both' | 'create' | 'dragright' {

    // check for active selection mode
    if (renderInfo.viewParams.activeSelectionMode) {
      renderInfo.viewParams.activeSelectionMode(renderInfo.workPackage);
      ev.preventDefault();
      return 'both'; // irrelevant
    }

    let direction:'both' | 'create' = 'both';
    this.workPackageTimeline.forceCursor('ew-resize');

    if (dateForCreate) {
      renderInfo.change.projectedResource.date = dateForCreate;
      direction = 'create';
      return direction;
    }

    this.updateLabels(true, labels, renderInfo.change);

    return direction;
  }

  public update(element:HTMLDivElement, labels:WorkPackageCellLabels|null, renderInfo:RenderInfo):boolean {
    const viewParams = renderInfo.viewParams;
    const date = moment(renderInfo.change.projectedResource.date);

    // abort if no date
    if (_.isNaN(date.valueOf())) {
      return false;
    }

    const diamond = jQuery('.diamond', element)[0];

    diamond.style.width = 15 + 'px';
    diamond.style.height = 15 + 'px';
    diamond.style.width = 15 + 'px';
    diamond.style.height = 15 + 'px';
    diamond.style.marginLeft = -(15 / 2) + (renderInfo.viewParams.pixelPerDay / 2) + 'px';
    this.applyTypeColor(renderInfo, diamond);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, 'days');
    element.style.left = calculatePositionValueForDayCountingPx(viewParams, offsetStart) + 'px';

    // Update labels if any
    if (labels) {
      this.updateLabels(false, labels, renderInfo.change);
    }

    this.checkForActiveSelectionMode(renderInfo, diamond);

    return true;
  }

  getMarginLeftOfLeftSide(renderInfo:RenderInfo):number {
    const change = renderInfo.change;
    const start = moment(change.projectedResource.date);
    const offsetStart = start.diff(renderInfo.viewParams.dateDisplayStart, 'days');
    return calculatePositionValueForDayCountingPx(renderInfo.viewParams, offsetStart);
  }

  getMarginLeftOfRightSide(ri:RenderInfo):number {
    return this.getMarginLeftOfLeftSide(ri) + ri.viewParams.pixelPerDay;
  }

  getPaddingLeftForIncomingRelationLines(renderInfo:RenderInfo):number {
    return (renderInfo.viewParams.pixelPerDay / 2) - 1;
  }

  getPaddingRightForOutgoingRelationLines(renderInfo:RenderInfo):number {
    return (15 / 2);
  }

  /**
   * Render a milestone element, a single day event with no resize, but
   * move functionality.
   */
  public render(renderInfo:RenderInfo):HTMLDivElement {
    const element = document.createElement('div');
    element.className = timelineElementCssClass + ' ' + this.type;

    const diamond = document.createElement('div');
    diamond.className = 'diamond';
    element.appendChild(diamond);

    return element;
  }

  createAndAddLabels(renderInfo:RenderInfo, element:HTMLElement):WorkPackageCellLabels {
    // create left label
    const labelLeft = document.createElement('div');
    labelLeft.classList.add(classNameLeftLabel, classNameHideOnHover);
    element.appendChild(labelLeft);

    // create right container
    const containerRight = document.createElement('div');
    containerRight.classList.add(classNameRightContainer);
    element.appendChild(containerRight);

    // create right label
    const labelRight = document.createElement('div');
    labelRight.classList.add(classNameRightLabel, classNameHideOnHover);
    containerRight.appendChild(labelRight);

    // create far right label
    const labelFarRight = document.createElement('div');
    labelFarRight.classList.add(classNameFarRightLabel, classNameHideOnHover);
    containerRight.appendChild(labelFarRight);

    // Create right hover label
    const labelHoverRight = document.createElement('div');
    labelHoverRight.classList.add(classNameRightHoverLabel, classNameShowOnHover, classNameHoverStyle);
    element.appendChild(labelHoverRight);

    // Create left hover label
    const labelHoverLeft = document.createElement('div');
    labelHoverLeft.classList.add(classNameLeftHoverLabel, classNameShowOnHover, classNameHoverStyle);
    element.appendChild(labelHoverLeft);

    const labels = new WorkPackageCellLabels(null, labelLeft, labelHoverLeft, labelRight, labelHoverRight, labelFarRight, renderInfo.withAlternativeLabels);
    this.updateLabels(false, labels, renderInfo.change);

    return labels;
  }

  protected renderHoverLabels(labels:WorkPackageCellLabels, change:WorkPackageChangeset) {
    if (labels.withAlternativeLabels) {
      this.renderLabel(change, labels, 'leftHover', 'date');
      this.renderLabel(change, labels, 'rightHover', 'subject');
    } else {
      this.renderLabel(change, labels, 'rightHover', 'date');
    }
  }

  protected updateLabels(activeDragNDrop:boolean,
    labels:WorkPackageCellLabels,
    change:WorkPackageChangeset) {

    const labelConfiguration = this.wpTableTimeline.getNormalizedLabels(change.projectedResource);

    if (!activeDragNDrop) {
      // normal display

      if (labels.withAlternativeLabels) {
        this.renderLabel(change, labels, 'right', 'subject');
      } else {
        // Show only one date field if left=start, right=dueDate
        if (labelConfiguration.left === 'startDate' && labelConfiguration.right === 'dueDate') {
          this.renderLabel(change, labels, 'left', null);
          this.renderLabel(change, labels, 'right', 'date');
        } else {
          this.renderLabel(change, labels, 'left', labelConfiguration.left);
          this.renderLabel(change, labels, 'right', labelConfiguration.right);
        }
      }

      this.renderLabel(change, labels, 'farRight', labelConfiguration.farRight);
    }

    // Update hover labels
    this.renderHoverLabels(labels, change);
  }

  protected renderLabel(change:WorkPackageChangeset,
    labels:WorkPackageCellLabels,
    position:LabelPosition|'leftHover'|'rightHover',
    attribute:string|null) {
    // Normalize attribute
    if (attribute === 'startDate' || attribute === 'dueDate') {
      attribute = 'date';
    }

    super.renderLabel(change, labels, position, attribute);
  }

}
