import * as moment from 'moment';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {
  calculatePositionValueForDayCountingPx,
  RenderInfo,
  timelineElementCssClass
} from '../wp-timeline';
import {CellDateMovement, LabelPosition, TimelineCellRenderer} from './timeline-cell-renderer';
import {
  classNameFarRightLabel,
  classNameHideOnHover,
  classNameHoverStyle,
  classNameLeftLabel,
  classNameRightContainer,
  classNameRightHoverLabel,
  classNameRightLabel,
  classNameShowOnHover,
  WorkPackageCellLabels
} from './wp-timeline-cell';
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';
import Moment = moment.Moment;

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {
  public get type():string {
    return 'milestone';
  }

  public isEmpty(wp:WorkPackageResource) {
    const date = moment(wp.date as any);
    const noDateValue = _.isNaN(date.valueOf());
    return noDateValue;
  }

  public canMoveDates(wp:WorkPackageResource) {
    return wp.schema.date.writable;
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
    diamond.style.backgroundColor = '#DDDDDD';
    diamond.style.left = '0.5em';
    diamond.style.height = '1em';
    diamond.style.width = '1em';
    placeholder.appendChild(diamond);

    return placeholder;
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and finish date .
   *
   */
  public assignDateValues(changeset:WorkPackageChangeset,
                          labels:WorkPackageCellLabels,
                          dates:any):void {

    this.assignDate(changeset, 'date', dates.date);
    this.updateLabels(true, labels, changeset);
  }

  /**
   * Handle movement by <delta> days of milestone.
   */
  public onDaysMoved(changeset:WorkPackageChangeset,
                     dayUnderCursor:Moment,
                     delta:number,
                     direction:'left' | 'right' | 'both' | 'create' | 'dragright') {

    const initialDate = changeset.workPackage.date;
    let dates:CellDateMovement = {};

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
      renderInfo.changeset.setValue('date', dateForCreate);
      direction = 'create';
      return direction;
    }

    this.updateLabels(true, labels, renderInfo.changeset);

    return direction;
  }

  public update(element:HTMLDivElement, labels:WorkPackageCellLabels|null, renderInfo:RenderInfo): boolean {
    const viewParams = renderInfo.viewParams;
    const date = moment(renderInfo.changeset.value('date'));

    // abort if no date
    if (_.isNaN(date.valueOf())) {
      return false;
    }

    const diamond = jQuery('.diamond', element)[0];

    element.style.width = 15 + 'px';
    element.style.height = 15 + 'px';
    diamond.style.width = 15 + 'px';
    diamond.style.height = 15 + 'px';
    diamond.style.marginLeft = -(15 / 2) + (renderInfo.viewParams.pixelPerDay / 2) + 'px';
    this.applyTypeColor(renderInfo.workPackage, diamond);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, 'days');
    element.style.left = calculatePositionValueForDayCountingPx(viewParams, offsetStart) + 'px';

    // Update labels if any
    if (labels) {
      this.updateLabels(false, labels, renderInfo.changeset);
    }

    this.checkForActiveSelectionMode(renderInfo, diamond);

    return true;
  }

  getMarginLeftOfLeftSide(renderInfo:RenderInfo):number {
    const changeset = renderInfo.changeset;
    let start = moment(changeset.value('date'));
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

    const labels = new WorkPackageCellLabels(null, labelLeft, null, labelRight, labelHoverRight, labelFarRight);
    this.updateLabels(false, labels, renderInfo.changeset);

    return labels;
  }

  protected renderHoverLabels(labels:WorkPackageCellLabels, changeset:WorkPackageChangeset) {
    this.renderLabel(changeset, labels, 'rightHover', 'date');
  }

  protected updateLabels(activeDragNDrop:boolean,
                         labels:WorkPackageCellLabels,
                         changeset:WorkPackageChangeset) {

    const labelConfiguration = this.wpTableTimeline.getNormalizedLabels(changeset.workPackage);

    if (!activeDragNDrop) {
      // normal display

      // Show only one date field if left=start, right=dueDate
      if (labelConfiguration.left === 'startDate' && labelConfiguration.right === 'dueDate') {
        this.renderLabel(changeset, labels, 'left', null);
        this.renderLabel(changeset, labels, 'right', 'date');
      } else {
        this.renderLabel(changeset, labels, 'left', labelConfiguration.left);
        this.renderLabel(changeset, labels, 'right', labelConfiguration.right);
      }

      this.renderLabel(changeset, labels, 'farRight', labelConfiguration.farRight);
    }

    // Update hover labels
    this.renderHoverLabels(labels, changeset);
  }

  protected renderLabel(changeset:WorkPackageChangeset,
                        labels:WorkPackageCellLabels,
                        position:LabelPosition|'leftHover'|'rightHover',
                        attribute:string|null) {
    // Normalize attribute
    if (attribute === 'startDate' || attribute === 'dueDate') {
      attribute = 'date';
    }

    super.renderLabel(changeset, labels, position, attribute);
  }

}
