import * as moment from 'moment';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {
  calculatePositionValueForDayCount,
  calculatePositionValueForDayCountingPx,
  RenderInfo,
  timelineBackgroundElementClass,
  timelineElementCssClass,
  timelineMarkerSelectionStartClass
} from '../wp-timeline';
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
import {classNameBarLabel, classNameLeftHandle, classNameRightHandle} from './wp-timeline-cell-mouse-handler';
import {WorkPackageTimelineTableController} from '../container/wp-timeline-container.directive';
import {DisplayFieldRenderer} from '../../../wp-edit-form/display-field-renderer';
import {Injector} from '@angular/core';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {HierarchyRenderPass} from "core-components/wp-fast-table/builders/modes/hierarchy/hierarchy-render-pass";
import Moment = moment.Moment;
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export interface CellDateMovement {
  // Target values to move work package to
  startDate?:moment.Moment;
  dueDate?:moment.Moment;
  // Target value to move milestone to
  date?:moment.Moment;
}

export type LabelPosition = 'left'|'right'|'farRight';

export class TimelineCellRenderer {
  @InjectField() wpTableTimeline:WorkPackageViewTimelineService;
  @InjectField() TimezoneService:TimezoneService;
  public fieldRenderer:DisplayFieldRenderer = new DisplayFieldRenderer(this.injector, 'timeline');

  protected dateDisplaysOnMouseMove:{ left?:HTMLElement; right?:HTMLElement } = {};

  constructor(readonly injector:Injector,
              readonly workPackageTimeline:WorkPackageTimelineTableController) {
  }

  public get type():string {
    return 'bar';
  }

  public canMoveDates(wp:WorkPackageResource) {
    return wp.schema.startDate.writable && wp.schema.dueDate.writable && wp.isAttributeEditable('startDate');
  }

  public isEmpty(wp:WorkPackageResource) {
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);
    const noStartAndDueValues = _.isNaN(start.valueOf()) && _.isNaN(due.valueOf());
    return noStartAndDueValues;
  }

  public displayPlaceholderUnderCursor(ev:MouseEvent, renderInfo:RenderInfo):HTMLElement {
    const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);

    const placeholder = document.createElement('div');
    placeholder.style.pointerEvents = 'none';
    placeholder.style.position = 'absolute';
    placeholder.style.height = '1em';
    placeholder.style.width = '30px';
    placeholder.style.zIndex = '9999';
    placeholder.style.left = (days * renderInfo.viewParams.pixelPerDay) + 'px';

    this.applyTypeColor(renderInfo, placeholder);

    return placeholder;
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and finish date.
   *
   */
  public assignDateValues(change:WorkPackageChangeset,
                          labels:WorkPackageCellLabels,
                          dates:any):void {

    this.assignDate(change, 'startDate', dates.startDate);
    this.assignDate(change, 'dueDate', dates.dueDate);

    this.updateLabels(true, labels, change);
  }

  /**
   * Handle movement by <delta> days of the work package to either (or both) edge(s)
   * depending on which initial date was set.
   */
  public onDaysMoved(change:WorkPackageChangeset,
                     dayUnderCursor:Moment,
                     delta:number,
                     direction:'left'|'right'|'both'|'create'|'dragright'):CellDateMovement {

    const initialStartDate = change.pristineResource.startDate;
    const initialDueDate = change.pristineResource.dueDate;

    const now = moment().format('YYYY-MM-DD');

    const startDate = moment(change.projectedResource.startDate);
    const dueDate = moment(change.projectedResource.dueDate);

    let dates:CellDateMovement = {};

    if (direction === 'left') {
      dates.startDate = moment(initialStartDate || initialDueDate).add(delta, 'days');
    } else if (direction === 'right') {
      dates.dueDate = moment(initialDueDate || now).add(delta, 'days');
    } else if (direction === 'both') {
      if (initialStartDate) {
        dates.startDate = moment(initialStartDate).add(delta, 'days');
      }
      if (initialDueDate) {
        dates.dueDate = moment(initialDueDate).add(delta, 'days');
      }
    } else if (direction === 'dragright') {
      dates.dueDate = startDate.clone().add(delta, 'days');
    }

    // avoid negative "overdrag" if only start or due are changed
    if (direction !== 'both') {
      if (dates.startDate !== undefined && dates.startDate.isAfter(dueDate)) {
        dates.startDate = dueDate;
      } else if (dates.dueDate !== undefined && dates.dueDate.isBefore(startDate)) {
        dates.dueDate = startDate;
      }
    }

    return dates;
  }

  public onMouseDown(ev:MouseEvent,
                     dateForCreate:string|null,
                     renderInfo:RenderInfo,
                     labels:WorkPackageCellLabels,
                     elem:HTMLElement):'left'|'right'|'both'|'dragright'|'create' {

    // check for active selection mode
    if (renderInfo.viewParams.activeSelectionMode) {
      renderInfo.viewParams.activeSelectionMode(renderInfo.workPackage);
      ev.preventDefault();
      return 'both'; // irrelevant
    }

    const projection = renderInfo.change.projectedResource;
    let direction:'left'|'right'|'both'|'dragright';

    // Update the cursor and maybe set start/due values
    if (jQuery(ev.target!).hasClass(classNameLeftHandle)) {
      // only left
      direction = 'left';
      this.workPackageTimeline.forceCursor('col-resize');
      if (projection.startDate === null) {
        projection.startDate = projection['dueDate'];
      }
    } else if (jQuery(ev.target!).hasClass(classNameRightHandle) || dateForCreate) {
      // only right
      direction = 'right';
      this.workPackageTimeline.forceCursor('col-resize');
    } else {
      // both
      direction = 'both';
      this.workPackageTimeline.forceCursor('ew-resize');
    }

    if (dateForCreate) {
      projection.startDate = dateForCreate;
      projection.dueDate = dateForCreate;
      direction = 'dragright';
    }

    this.updateLabels(true, labels, renderInfo.change);

    return direction;
  }

  public onMouseDownEnd(labels:WorkPackageCellLabels, change:WorkPackageChangeset) {
    this.updateLabels(false, labels, change);
  }

  /**
   * @return true, if the element should still be displayed.
   *         false, if the element must be removed from the timeline.
   */
  public update(element:HTMLDivElement, labels:WorkPackageCellLabels|null, renderInfo:RenderInfo):boolean {
    const change = renderInfo.change;
    const bar = element.querySelector(`.${timelineBackgroundElementClass}`) as HTMLElement;

    const viewParams = renderInfo.viewParams;
    let start = moment(change.projectedResource.startDate);
    let due = moment(change.projectedResource.dueDate);

    if (_.isNaN(start.valueOf()) && _.isNaN(due.valueOf())) {
      element.style.visibility = 'hidden';
    } else {
      element.style.visibility = 'visible';
    }

    // only start date, fade out bar to the right
    if (_.isNaN(due.valueOf()) && !_.isNaN(start.valueOf())) {
      // Set due date to today
      due = moment();
      bar.style.backgroundImage = `linear-gradient(90deg, rgba(255,255,255,0) 0%, #F1F1F1 100%)`;
    }

    // only finish date, fade out bar to the left
    if (_.isNaN(start.valueOf()) && !_.isNaN(due.valueOf())) {
      start = due.clone();
      bar.style.backgroundImage = `linear-gradient(90deg, #F1F1F1 0%, rgba(255,255,255,0) 80%)`;
    }

    // offset left
    const offsetStart = start.diff(viewParams.dateDisplayStart, 'days');
    element.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);

    // duration
    const duration = due.diff(start, 'days') + 1;
    element.style.width = calculatePositionValueForDayCount(viewParams, duration);

    // ensure minimum width
    if (!_.isNaN(start.valueOf()) || !_.isNaN(due.valueOf())) {
      const minWidth = _.max([renderInfo.viewParams.pixelPerDay, 2]);
      element.style.minWidth = minWidth + 'px';
    }

    // Update labels if any
    if (labels) {
      this.updateLabels(false, labels, change);
    }

    this.checkForActiveSelectionMode(renderInfo, bar);
    this.checkForSpecialDisplaySituations(renderInfo, bar);
    this.applyTypeColor(renderInfo, bar);

    return true;
  }

  protected checkForActiveSelectionMode(renderInfo:RenderInfo, element:HTMLElement) {
    if (renderInfo.viewParams.activeSelectionMode) {
      element.style.backgroundImage = ''; // required! unable to disable "fade out bar" with css

      if (renderInfo.viewParams.selectionModeStart === '' + renderInfo.workPackage.id!) {
        jQuery(element).addClass(timelineMarkerSelectionStartClass);
        element.style.background = 'none';
      }
    }
  }

  getMarginLeftOfLeftSide(renderInfo:RenderInfo):number {
    const projection = renderInfo.change.projectedResource;

    let start = moment(projection.startDate);
    let due = moment(projection.dueDate);
    start = _.isNaN(start.valueOf()) ? due.clone() : start;

    const offsetStart = start.diff(renderInfo.viewParams.dateDisplayStart, 'days');

    return calculatePositionValueForDayCountingPx(renderInfo.viewParams, offsetStart);
  }

  getMarginLeftOfRightSide(renderInfo:RenderInfo):number {
    const projection = renderInfo.change.projectedResource;

    let start = moment(projection.startDate);
    let due = moment(projection.dueDate);

    start = _.isNaN(start.valueOf()) ? due.clone() : start;
    due = _.isNaN(due.valueOf()) ? start.clone() : due;

    const offsetStart = start.diff(renderInfo.viewParams.dateDisplayStart, 'days');
    const duration = due.diff(start, 'days') + 1;

    return calculatePositionValueForDayCountingPx(renderInfo.viewParams, offsetStart + duration);
  }

  getPaddingLeftForIncomingRelationLines(renderInfo:RenderInfo):number {
    return renderInfo.viewParams.pixelPerDay / 8;
  }

  getPaddingRightForOutgoingRelationLines(renderInfo:RenderInfo):number {
    return 0;
  }

  /**
   * Render the generic cell element, a bar spanning from
   * start to finish date.
   */
  public render(renderInfo:RenderInfo):HTMLDivElement {
    const container = document.createElement('div');
    const bar = document.createElement('div');
    const left = document.createElement('div');
    const right = document.createElement('div');

    container.className = timelineElementCssClass + ' ' + this.type;
    bar.className = timelineBackgroundElementClass;
    left.className = classNameLeftHandle;
    right.className = classNameRightHandle;
    container.appendChild(bar);
    container.appendChild(left);
    container.appendChild(right);

    return container;
  }

  createAndAddLabels(renderInfo:RenderInfo, element:HTMLElement):WorkPackageCellLabels {
    // create center label
    const labelCenter = document.createElement('div');
    labelCenter.classList.add(classNameBarLabel);
    this.applyTypeColor(renderInfo, labelCenter);
    element.appendChild(labelCenter);

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

    // create left hover label
    const labelHoverLeft = document.createElement('div');
    labelHoverLeft.classList.add(classNameLeftHoverLabel, classNameShowOnHover, classNameHoverStyle);
    element.appendChild(labelHoverLeft);

    // create right hover label
    const labelHoverRight = document.createElement('div');
    labelHoverRight.classList.add(classNameRightHoverLabel, classNameShowOnHover, classNameHoverStyle);
    element.appendChild(labelHoverRight);

    const labels = new WorkPackageCellLabels(labelCenter, labelLeft, labelHoverLeft, labelRight, labelHoverRight, labelFarRight);
    this.updateLabels(false, labels, renderInfo.change);

    return labels;
  }

  protected applyTypeColor(renderInfo:RenderInfo, bg:HTMLElement):void {
    let wp = renderInfo.workPackage;
    let type = wp.type;
    let selectionMode = renderInfo.viewParams.activeSelectionMode;

    // Don't apply the class in selection mode or for parents (clamps)
    const id = type.id;
    if (selectionMode || this.isParentWithVisibleChildren(wp)) {
      bg.classList.remove(Highlighting.backgroundClass('type', id!));
    } else {
      bg.classList.add(Highlighting.backgroundClass('type', id!));
    }
  }

  protected assignDate(change:WorkPackageChangeset, attributeName:string, value:moment.Moment) {
    if (value) {
      change.projectedResource[attributeName] = value.format('YYYY-MM-DD');
    }
  }

  /**
   * Changes the presentation of the work package.
   *
   * Known cases:
   * 1. Display a clamp if this work package is a parent element
   */
  checkForSpecialDisplaySituations(renderInfo:RenderInfo, bar:HTMLElement) {
    const wp = renderInfo.workPackage;
    let selectionMode = renderInfo.viewParams.activeSelectionMode;

    // Cannot edit the work package if it has children
    if (!wp.isLeaf && !selectionMode) {
      bar.classList.add('-readonly');
    } else {
      bar.classList.remove('-readonly');
    }

    // Display the parent as clamp-style when it has children in the table
    if (this.isParentWithVisibleChildren(wp)) {
      bar.classList.add('-clamp-style');
      bar.style.borderStyle = 'solid';
      bar.style.borderWidth = '2px';
      bar.style.borderBottom = 'none';
      bar.style.background = 'none';
    }
  }

  protected updateLabels(activeDragNDrop:boolean,
                         labels:WorkPackageCellLabels,
                         change:WorkPackageChangeset) {

    const labelConfiguration = this.wpTableTimeline.getNormalizedLabels(change.projectedResource);

    if (!activeDragNDrop) {
      // normal display
      this.renderLabel(change, labels, 'left', labelConfiguration.left);
      this.renderLabel(change, labels, 'right', labelConfiguration.right);
      this.renderLabel(change, labels, 'farRight', labelConfiguration.farRight);
    }

    // Update hover labels
    this.renderHoverLabels(labels, change);
  }

  protected renderHoverLabels(labels:WorkPackageCellLabels, change:WorkPackageChangeset) {
    this.renderLabel(change, labels, 'leftHover', 'startDate');
    this.renderLabel(change, labels, 'rightHover', 'dueDate');
  }

  protected renderLabel(change:WorkPackageChangeset,
                        labels:WorkPackageCellLabels,
                        position:LabelPosition|'leftHover'|'rightHover',
                        attribute:string|null) {

    // Get the label position
    // Skip label if it does not exist (milestones)
    let label = labels[position];
    if (!label) {
      return;
    }

    // Reset label value
    label.innerHTML = '';

    if (attribute === null) {
      label.classList.remove('not-empty');
      return;
    }

    // Get the rendered field
    let [field, span] = this.fieldRenderer.renderFieldValue(change.projectedResource, attribute, change);

    if (label && field && span) {
      span.classList.add('label-content');
      label.appendChild(span);
      label.classList.add('not-empty');
    } else if (label) {
      label.classList.remove('not-empty');
    }
  }

  protected isParentWithVisibleChildren(wp:WorkPackageResource):boolean {
    if (!this.workPackageTimeline.inHierarchyMode) {
      return false;
    }

    const renderPass = this.workPackageTimeline.workPackageTable.lastRenderPass as HierarchyRenderPass|null;
    if (renderPass) {
      return !!renderPass.parentsWithVisibleChildren[wp.id!];
    }

    return false;
  }
}
