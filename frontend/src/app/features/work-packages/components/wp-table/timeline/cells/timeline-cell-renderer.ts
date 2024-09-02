import * as moment from 'moment';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { DisplayFieldRenderer } from 'core-app/shared/components/fields/display/display-field-renderer';
import { Injector } from '@angular/core';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { HierarchyRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/hierarchy/hierarchy-render-pass';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import { WorkPackageCellLabels } from './wp-timeline-cell-labels';
import {
  calculatePositionValueForDayCount,
  calculatePositionValueForDayCountingPx,
  RenderInfo,
  timelineBackgroundElementClass,
  timelineElementCssClass,
  timelineMarkerSelectionStartClass,
} from '../wp-timeline';
import Moment = moment.Moment;

export interface CellDateMovement {
  // Target values to move work package to
  startDate?:moment.Moment;
  dueDate?:moment.Moment;
  // Target value to move milestone to
  date?:moment.Moment;
}

export type LabelPosition = 'left'|'right'|'farRight';
export type MouseDirection = 'left'|'right'|'both'|'create'|'dragright';

export const classNameLeftLabel = 'labelLeft';
export const classNameRightContainer = 'containerRight';
export const classNameRightLabel = 'labelRight';
export const classNameLeftHoverLabel = 'labelHoverLeft';
export const classNameRightHoverLabel = 'labelHoverRight';
export const classNameHoverStyle = '-label-style';
export const classNameFarRightLabel = 'labelFarRight';
export const classNameShowOnHover = 'show-on-hover';
export const classNameHideOnHover = 'hide-on-hover';
export const classNameLeftHandle = 'leftHandle';
export const classNameRightHandle = 'rightHandle';
export const classNameBarLabel = 'bar-label';

export class TimelineCellRenderer {
  @InjectField() wpTableTimeline:WorkPackageViewTimelineService;

  @InjectField() weekdayService:WeekdayService;

  @InjectField() schemaCache:SchemaCacheService;

  @InjectField() I18n!:I18nService;

  public text = {
    label_children_derived_duration: this.I18n.t('js.label_children_derived_duration'),
  };

  public ganttChartRowHeight:number;

  public mouseDirection:MouseDirection;

  public fieldRenderer:DisplayFieldRenderer = new DisplayFieldRenderer(this.injector, 'timeline');

  protected mouseDownCursorType:string;

  constructor(readonly injector:Injector,
    readonly workPackageTimeline:WorkPackageTimelineTableController) {
    this.ganttChartRowHeight = +getComputedStyle(document.documentElement)
      .getPropertyValue('--table-timeline--row-height')
      .replace('px', '');
  }

  public get type():string {
    return 'bar';
  }

  public canMoveDates(wp:WorkPackageResource):boolean {
    const schema = this.schemaCache.of(wp);
    return schema.startDate.writable && schema.dueDate.writable && schema.isAttributeEditable('startDate');
  }

  public isEmpty(wp:WorkPackageResource) {
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);
    const noStartAndDueValues = _.isNaN(start.valueOf()) && _.isNaN(due.valueOf());
    return noStartAndDueValues;
  }

  public displayPlaceholderUnderCursor(ev:MouseEvent, renderInfo:RenderInfo):HTMLElement {
    const [dateUnderCursor, dayOffset] = this.cursorDateAndDayOffset(ev, renderInfo);
    const duration = this.displayDurationForDate(renderInfo, dateUnderCursor);
    const width = duration * renderInfo.viewParams.pixelPerDay || 30;

    const placeholder = document.createElement('div');
    placeholder.style.pointerEvents = 'none';
    placeholder.style.position = 'absolute';
    placeholder.style.height = '1em';
    placeholder.style.width = `${width}px`;
    placeholder.style.zIndex = '9999';
    placeholder.style.left = `${dayOffset * renderInfo.viewParams.pixelPerDay}px`;
    this.applyTypeColor(renderInfo, placeholder);

    return placeholder;
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and finish date.
   *
   */
  public assignDateValues(
    change:WorkPackageChangeset,
    labels:WorkPackageCellLabels,
    dates:CellDateMovement,
  ):void {
    this.assignDate(change, 'startDate', dates.startDate as moment.Moment);
    this.assignDate(change, 'dueDate', dates.dueDate as moment.Moment);

    this.updateLabels(true, labels, change);
  }

  /**
   * Handle movement by <delta> days of the work package to either (or both) edge(s)
   * depending on which initial date was set.
   */
  public onDaysMoved(change:WorkPackageChangeset,
    dayUnderCursor:Moment,
    delta:number,
    direction:MouseDirection):CellDateMovement {
    const initialStartDate = change.pristineResource.startDate;
    const initialDueDate = change.pristineResource.dueDate;

    const now = moment().format('YYYY-MM-DD');

    const startDate = moment(change.projectedResource.startDate);
    const dueDate = moment(change.projectedResource.dueDate);

    const dates:CellDateMovement = {};

    if (direction === 'left') {
      dates.startDate = moment(initialStartDate || initialDueDate).add(delta, 'days');
    } else if (direction === 'right') {
      // When no due date is present and the start date is in the past,
      // we assume the task hasn't finished yet, meaning the end date is not in the past.
      // To cover this case we have to choose the start date, only when it's in the future,
      // and choose now if the start date is in the past.
      const calculatedDueDate = initialDueDate || (now > initialStartDate ? now : initialStartDate);
      dates.dueDate = moment(calculatedDueDate).add(delta, 'days');
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
    labels:WorkPackageCellLabels):MouseDirection {
    // check for active selection mode
    if (renderInfo.viewParams.activeSelectionMode) {
      renderInfo.viewParams.activeSelectionMode(renderInfo.workPackage);
      ev.preventDefault();
      this.mouseDirection = 'both';
      return 'both'; // irrelevant
    }

    const projection = renderInfo.change.projectedResource;
    let direction:Exclude<MouseDirection, 'create'>;

    // Update the cursor and maybe set start/due values
    if (jQuery(ev.target!).hasClass(classNameLeftHandle)) {
      // only left
      direction = 'left';
      this.mouseDirection = 'left';
      this.mouseDownCursorType = 'col-resize';
      if (projection.startDate === null) {
        projection.startDate = projection.dueDate;
      }
    } else if (jQuery(ev.target!).hasClass(classNameRightHandle) || dateForCreate) {
      // only right
      direction = 'right';
      this.mouseDirection = 'right';
      this.mouseDownCursorType = 'col-resize';
    } else {
      // both
      direction = 'both';
      this.mouseDirection = 'both';
      this.mouseDownCursorType = 'ew-resize';
    }

    this.workPackageTimeline.forceCursor(this.mouseDownCursorType);

    if (dateForCreate) {
      const dateUnderCursor = this.cursorDateAndDayOffset(ev, renderInfo)[0];
      const duration = this.displayDurationForDate(renderInfo, dateUnderCursor) - 1;

      projection.startDate = dateForCreate;
      projection.dueDate = moment(dateForCreate).add(duration, 'days').format('YYYY-MM-DD');
      direction = 'dragright';
      this.mouseDirection = 'dragright';
    }

    this.updateLabels(true, labels, renderInfo.change);

    return direction;
  }

  public onMouseDownEnd(labels:WorkPackageCellLabels, change:WorkPackageChangeset) {
    // Reset the cursor set by onMouseDown
    this.mouseDownCursorType = '';
    this.workPackageTimeline.forceCursor(this.mouseDownCursorType);
    this.updateLabels(false, labels, change);
  }

  /**
   * @return true, if the element should still be displayed.
   *         false, if the element must be removed from the timeline.
   */
  public update(element:HTMLDivElement, labels:WorkPackageCellLabels|null, renderInfo:RenderInfo):boolean {
    const { change } = renderInfo;
    const bar = element.querySelector(`.${timelineBackgroundElementClass}`) as HTMLElement;
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
      bar.setAttribute('style', 'background-image: linear-gradient(90deg, rgba(255,255,255,0) 0%, #F1F1F1 100%) !important');
    }

    // only finish date, fade out bar to the left
    if (_.isNaN(start.valueOf()) && !_.isNaN(due.valueOf())) {
      start = due.clone();
      bar.setAttribute('style', 'background-image: linear-gradient(90deg, #F1F1F1 0%, rgba(255,255,255,0) 80%) !important');
    }

    this.setElementPositionAndSize(element, renderInfo, start, due);

    // Update labels if any
    if (labels) {
      this.updateLabels(false, labels, change);
    }

    this.checkForActiveSelectionMode(renderInfo, bar);
    this.checkForSpecialDisplaySituations(renderInfo, bar);
    this.applyTypeColor(renderInfo, bar);

    return true;
  }

  public cursorDateAndDayOffset(ev:MouseEvent, renderInfo:RenderInfo):[Moment, number] {
    const dayOffset = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
    const dateUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(dayOffset, 'days');
    return [dateUnderCursor, dayOffset];
  }

  protected checkForActiveSelectionMode(renderInfo:RenderInfo, element:HTMLElement) {
    if (renderInfo.viewParams.activeSelectionMode) {
      element.style.backgroundImage = ''; // required! unable to disable "fade out bar" with css

      if (renderInfo.viewParams.selectionModeStart === `${renderInfo.workPackage.id!}`) {
        jQuery(element).addClass(timelineMarkerSelectionStartClass);
        element.style.background = 'none';
      }
    }
  }

  /**
   * Takes the date under the cursor and the work package's duration.
   * It calculates the adjusted duration based on the number of NonWorkingDays
   * that fall in the range of the ( date .. date + duration ).
   * @param renderInfo
   * @param date where we start the duration calculation from
   * @return {number} the NonWorkingDays adjusted duration
   */

  protected displayDurationForDate(renderInfo:RenderInfo, date:Moment):number {
    const { workPackage } = renderInfo;
    let duration = Number(moment.duration(workPackage.duration || 'P1D').asDays().toFixed(0));

    if (workPackage.ignoreNonWorkingDays) {
      return duration;
    }

    const { dateDisplayEnd } = renderInfo.viewParams;
    let newDuration = 0;

    for (newDuration; newDuration < duration; newDuration++) {
      const currentDate = date.clone().add(newDuration, 'days');

      // Stop adding duration when we reach end of the visible table
      if (currentDate > dateDisplayEnd) {
        break;
      }
      // Extend the duration if the currentDate is non-working
      if (this.weekdayService.isNonWorkingDay(currentDate.toDate() || this.workPackageTimeline.isNonWorkingDay(currentDate.toDate()))) {
        duration += 1;
      }
    }
    return newDuration;
  }

  getMarginLeftOfLeftSide(renderInfo:RenderInfo):number {
    const projection = renderInfo.change.projectedResource;

    let start = moment(projection.startDate);
    const due = moment(projection.dueDate);
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

    container.className = `${timelineElementCssClass} ${this.type}`;
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
    const wp = renderInfo.workPackage;
    const { type } = wp;
    const selectionMode = renderInfo.viewParams.activeSelectionMode;

    // Don't apply the class in selection mode
    const { id } = type;
    if (selectionMode) {
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

  setElementPositionAndSize(element:HTMLElement, renderInfo:RenderInfo, start:moment.Moment, due:moment.Moment) {
    const { viewParams } = renderInfo;
    // offset left
    const offsetStart = start.diff(viewParams.dateDisplayStart, 'days');
    element.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);

    // duration
    const duration = due.diff(start, 'days') + 1;
    element.style.width = calculatePositionValueForDayCount(viewParams, duration);

    // ensure minimum width
    if (!_.isNaN(start.valueOf()) || !_.isNaN(due.valueOf())) {
      const minWidth = _.max([renderInfo.viewParams.pixelPerDay, 2]);
      element.style.minWidth = `${minWidth}px`;
    }
  }

  cursorOrDatesAreNonWorking(evOrDates:MouseEvent|Moment[], renderInfo:RenderInfo, direction?:MouseDirection|null):boolean {
    if (renderInfo.workPackage.ignoreNonWorkingDays) {
      return false;
    }

    const dates = (evOrDates instanceof MouseEvent)
      ? [this.cursorDateAndDayOffset(evOrDates, renderInfo)[0]]
      : evOrDates;
    if (!renderInfo.workPackage.ignoreNonWorkingDays && direction === 'both'
      && (this.weekdayService.isNonWorkingDay(dates[dates.length - 1].toDate() || this.workPackageTimeline.isNonWorkingDay(dates[dates.length - 1].toDate())))) {
      return false;
    }
    return dates.some((date) => (this.weekdayService.isNonWorkingDay(date.toDate()) || this.workPackageTimeline.isNonWorkingDay(date.toDate())));
  }

  /**
   * Changes the presentation of the work package.
   *
   * Known cases:
   * 1. Display a clamp if this work package is a parent element
   *    and display a box wrapping all the visible children when the
   *    parent is hovered
   */
  checkForSpecialDisplaySituations(renderInfo:RenderInfo, bar:HTMLElement) {
    const wp = renderInfo.workPackage;
    const row = bar.parentElement!.parentElement!;
    const selectionMode = renderInfo.viewParams.activeSelectionMode;

    // Cannot edit the work package if it has children
    // and it is not on 'Manual scheduling' mode
    if (!wp.isLeaf && !selectionMode && !wp.scheduleManually) {
      bar.classList.add('-readonly');
    } else {
      bar.classList.remove('-readonly');
    }

    // Display the children's duration clamp
    if (wp.derivedStartDate && wp.derivedDueDate) {
      const derivedStartDate = moment(wp.derivedStartDate);
      const derivedDueDate = moment(wp.derivedDueDate);
      const startDate = moment(renderInfo.change.projectedResource.startDate);
      const dueDate = moment(renderInfo.change.projectedResource.dueDate);
      const previousChildrenDurationBar = row.querySelector('.children-duration-bar');
      const childrenDurationBar = document.createElement('div');
      const childrenDurationHoverContainer = document.createElement('div');
      const visibleChildren = document.querySelectorAll(`.wp-timeline-cell.__hierarchy-group-${wp.id}:not([class*='__collapsed-group'])`).length || 0;

      childrenDurationBar.classList.add('children-duration-bar', '-clamp-style');
      childrenDurationBar.title = this.text.label_children_derived_duration;
      childrenDurationHoverContainer.classList.add('children-duration-hover-container');
      childrenDurationHoverContainer.style.height = `${this.ganttChartRowHeight * visibleChildren + 10}px`;

      if (derivedStartDate.isBefore(startDate) || derivedDueDate.isAfter(dueDate)) {
        childrenDurationBar.classList.add('-duration-overflow');
      }

      this.setElementPositionAndSize(childrenDurationBar, renderInfo, derivedStartDate, derivedDueDate);

      if (previousChildrenDurationBar) {
        previousChildrenDurationBar.remove();
      }

      childrenDurationBar.appendChild(childrenDurationHoverContainer);
      row.appendChild(childrenDurationBar);
    }

    // Check for non-working days and display a not-allowed cursor
    // when the startDate, dueDate are non-working days
    const { startDate, dueDate } = renderInfo.change.projectedResource;
    const invalidDates = this.cursorOrDatesAreNonWorking([moment(startDate), moment(dueDate)], renderInfo, this.mouseDirection);

    if (invalidDates) {
      this.workPackageTimeline.forceCursor('not-allowed');
    } else {
      // Restore the previous cursor set by onMouseDown
      this.workPackageTimeline.forceCursor(this.mouseDownCursorType);
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
    const label = labels[position];
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
    const [field, span] = this.fieldRenderer.renderFieldValue(change.projectedResource, attribute, change);

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
