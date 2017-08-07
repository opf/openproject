import * as moment from 'moment';
import {$injectNow} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {
  calculatePositionValueForDayCount,
  calculatePositionValueForDayCountingPx,
  RenderInfo,
  timelineElementCssClass,
  timelineMarkerSelectionStartClass
} from '../wp-timeline';
import {
  classNameFarRightLabel,
  classNameLeftLabel,
  classNameRightContainer,
  classNameRightLabel,
  classNameShowOnHover,
  WorkPackageCellLabels
} from './wp-timeline-cell';
import {classNameBarLabel, classNameLeftHandle, classNameRightHandle} from './wp-timeline-cell-mouse-handler';
import Moment = moment.Moment;
import {WorkPackageTimelineTableController} from '../container/wp-timeline-container.directive';
import {hasChildrenInTable} from '../../../wp-fast-table/helpers/wp-table-hierarchy-helpers';
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';

interface CellDateMovement {
  // Target values to move work package to
  startDate?:moment.Moment;
  dueDate?:moment.Moment;
}

function calculateForegroundColor(backgroundColor:string):string {
  return 'red';
}

export class TimelineCellRenderer {

  protected TimezoneService:any;

  protected dateDisplaysOnMouseMove:{ left?:HTMLElement; right?:HTMLElement } = {};

  constructor(public workPackageTimeline:WorkPackageTimelineTableController) {
  }

  public get type():string {
    return 'bar';
  }

  public get fallbackColor():string {
    return 'rgba(50, 50, 50, 0.1)';
  }

  public isEmpty(wp:WorkPackageResourceInterface) {
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);
    const noStartAndDueValues = _.isNaN(start.valueOf()) && _.isNaN(due.valueOf());
    return noStartAndDueValues;
  }

  public displayPlaceholderUnderCursor(ev:MouseEvent, renderInfo:RenderInfo):HTMLElement {
    const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);

    const placeholder = document.createElement('div');
    placeholder.style.pointerEvents = 'none';
    placeholder.style.backgroundColor = '#DDDDDD';
    placeholder.style.position = 'absolute';
    placeholder.style.height = '1em';
    placeholder.style.width = '30px';
    placeholder.style.zIndex = '9999';
    placeholder.style.left = (days * renderInfo.viewParams.pixelPerDay) + 'px';

    return placeholder;
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and due date.
   *
   */
  public assignDateValues(changeset:WorkPackageChangeset,
                          labels:WorkPackageCellLabels,
                          dates:CellDateMovement) {

    this.assignDate(changeset, 'startDate', dates.startDate!);
    this.assignDate(changeset, 'dueDate', dates.dueDate!);

    this.updateLabels(true, labels, changeset);
  }

  /**
   * Handle movement by <delta> days of the work package to either (or both) edge(s)
   * depending on which initial date was set.
   */
  public onDaysMoved(changeset:WorkPackageChangeset,
                     dayUnderCursor:Moment,
                     delta:number,
                     direction:'left' | 'right' | 'both' | 'create' | 'dragright'):CellDateMovement {

    const initialStartDate = changeset.workPackage.startDate;
    const initialDueDate = changeset.workPackage.dueDate;

    const startDate = moment(changeset.value('startDate'));
    const dueDate = moment(changeset.value('dueDate'));

    let dates:CellDateMovement = {};

    if (direction === 'left') {
      dates.startDate = moment(initialStartDate || initialDueDate).add(delta, 'days');
    } else if (direction === 'right') {
      dates.dueDate = moment(initialDueDate || initialStartDate).add(delta, 'days');
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
      if (dates.startDate != undefined && dates.startDate.isAfter(dueDate)) {
        dates.startDate = dueDate;
      } else if (dates.dueDate != undefined && dates.dueDate.isBefore(startDate)) {
        dates.dueDate = startDate;
      }
    }

    return dates;
  }

  public onMouseDown(ev:MouseEvent,
                     dateForCreate:string | null,
                     renderInfo:RenderInfo,
                     labels:WorkPackageCellLabels,
                     elem:HTMLElement):'left' | 'right' | 'both' | 'dragright' | 'create' {

    // check for active selection mode
    if (renderInfo.viewParams.activeSelectionMode) {
      renderInfo.viewParams.activeSelectionMode(renderInfo.workPackage);
      ev.preventDefault();
      return 'both'; // irrelevant
    }

    const changeset = renderInfo.changeset;
    let direction:'left' | 'right' | 'both' | 'dragright';

    // Update the cursor and maybe set start/due values
    if (jQuery(ev.target).hasClass(classNameLeftHandle)) {
      // only left
      direction = 'left';
      this.forceCursor('w-resize');
      if (changeset.value('startDate') === null) {
        changeset.setValue('startDate', changeset.value('dueDate'));
      }
    } else if (jQuery(ev.target).hasClass(classNameRightHandle) || dateForCreate) {
      // only right
      direction = 'right';
      this.forceCursor('e-resize');
      if (changeset.value('dueDate') === null) {
        changeset.setValue('dueDate', changeset.value('startDate'));
      }
    } else {
      // both
      direction = 'both';
      this.forceCursor('ew-resize');
    }

    if (dateForCreate) {
      changeset.setValue('startDate', dateForCreate);
      changeset.setValue('dueDate', dateForCreate);
      direction = 'dragright';
    }

    this.updateLabels(true, labels, renderInfo.changeset);

    return direction;
  }

  public onMouseDownEnd(labels:WorkPackageCellLabels, changeset:WorkPackageChangeset) {
    this.updateLabels(false, labels, changeset);
  }

  /**
   * @return true, if the element should still be displayed.
   *         false, if the element must be removed from the timeline.
   */
  public update(bar:HTMLDivElement, renderInfo:RenderInfo):boolean {
    const changeset = renderInfo.changeset;

    // general settings - bar
    bar.style.backgroundColor = this.typeColor(renderInfo.workPackage);

    const viewParams = renderInfo.viewParams;
    let start = moment(changeset.value('startDate'));
    let due = moment(changeset.value('dueDate'));

    if (_.isNaN(start.valueOf()) && _.isNaN(due.valueOf())) {
      bar.style.visibility = 'hidden';
    } else {
      bar.style.visibility = 'visible';
    }

    // only start date, fade out bar to the right
    if (_.isNaN(due.valueOf()) && !_.isNaN(start.valueOf())) {
      due = start.clone();
      bar.style.backgroundColor = 'inherit';
      const color = this.typeColor(renderInfo.workPackage);
      bar.style.backgroundImage = `linear-gradient(90deg, ${color} 0%, rgba(255,255,255,0) 80%)`;
    }

    // only due date, fade out bar to the left
    if (_.isNaN(start.valueOf()) && !_.isNaN(due.valueOf())) {
      start = due.clone();
      bar.style.backgroundColor = 'inherit';
      const color = this.typeColor(renderInfo.workPackage);
      bar.style.backgroundImage = `linear-gradient(90deg, rgba(255,255,255,0) 0%, ${color} 100%)`;
    }

    // offset left
    const offsetStart = start.diff(viewParams.dateDisplayStart, 'days');
    bar.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);

    // duration
    const duration = due.diff(start, 'days') + 1;
    bar.style.width = calculatePositionValueForDayCount(viewParams, duration);

    // ensure minimum width
    if (!_.isNaN(start.valueOf()) || !_.isNaN(due.valueOf())) {
      const minWidth = _.max([renderInfo.viewParams.pixelPerDay, 2]);
      bar.style.minWidth = minWidth + 'px';
    }

    this.checkForActiveSelectionMode(renderInfo, bar);
    this.checkForSpecialDisplaySituations(renderInfo, bar);

    return true;
  }

  protected checkForActiveSelectionMode(renderInfo:RenderInfo, element:HTMLElement) {
    if (renderInfo.viewParams.activeSelectionMode) {
      element.style.backgroundImage = null; // required! unable to disable "fade out bar" with css

      if (renderInfo.viewParams.selectionModeStart === '' + renderInfo.workPackage.id) {
        jQuery(element).addClass(timelineMarkerSelectionStartClass);
        element.style.background = null;
      }
    }
  }

  getMarginLeftOfLeftSide(renderInfo:RenderInfo):number {
    const changeset = renderInfo.changeset;

    let start = moment(changeset.value('startDate'));
    let due = moment(changeset.value('dueDate'));
    start = _.isNaN(start.valueOf()) ? due.clone() : start;

    const offsetStart = start.diff(renderInfo.viewParams.dateDisplayStart, 'days');

    return calculatePositionValueForDayCountingPx(renderInfo.viewParams, offsetStart);
  }

  getMarginLeftOfRightSide(renderInfo:RenderInfo):number {
    const changeset = renderInfo.changeset;

    let start = moment(changeset.value('startDate'));
    let due = moment(changeset.value('dueDate'));

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
   * start to due date.
   */
  public render(renderInfo:RenderInfo):HTMLDivElement {
    const bar = document.createElement('div');
    const left = document.createElement('div');
    const right = document.createElement('div');

    bar.className = timelineElementCssClass + ' ' + this.type;
    left.className = classNameLeftHandle;
    right.className = classNameRightHandle;
    bar.appendChild(left);
    bar.appendChild(right);

    return bar;
  }

  createAndAddLabels(renderInfo:RenderInfo, element:HTMLElement):WorkPackageCellLabels {
    // create center label
    const labelCenter = document.createElement('div');
    labelCenter.classList.add(classNameBarLabel);
    const backgroundColor = this.typeColor(renderInfo.workPackage);
    labelCenter.style.color = calculateForegroundColor(backgroundColor);
    element.appendChild(labelCenter);

    // create left label
    const labelLeft = document.createElement('div');
    labelLeft.classList.add(classNameLeftLabel);
    labelLeft.classList.add(classNameShowOnHover);
    element.appendChild(labelLeft);

    // create right container
    const containerRight = document.createElement('div');
    containerRight.classList.add(classNameRightContainer);
    element.appendChild(containerRight);

    // create right label
    const labelRight = document.createElement('div');
    labelRight.classList.add(classNameRightLabel);
    labelRight.classList.add(classNameShowOnHover);
    containerRight.appendChild(labelRight);

    // create far right label
    const labelFarRight = document.createElement('div');
    labelFarRight.classList.add(classNameFarRightLabel);
    labelFarRight.classList.add(classNameShowOnHover);
    containerRight.appendChild(labelFarRight);

    const labels = new WorkPackageCellLabels(labelCenter, labelLeft, labelRight, labelFarRight);
    this.updateLabels(false, labels, renderInfo.changeset);

    return labels;
  }

  protected typeColor(wp:WorkPackageResourceInterface):string {
    let type = wp.type && wp.type.state.value;
    if (type && type.color) {
      return type.color;
    }

    return this.fallbackColor;
  }

  protected assignDate(changeset:WorkPackageChangeset, attributeName:string, value:moment.Moment) {
    if (value) {
      changeset.setValue(attributeName, value.format('YYYY-MM-DD'));
    }
  }

  /**
   * Force the cursor to the given cursor type.
   */
  protected forceCursor(cursor:string) {
    jQuery('.hascontextmenu').css('cursor', cursor);
    jQuery('.' + timelineElementCssClass).css('cursor', cursor);
  }

  /**
   * Changes the presentation of the work package.
   *
   * Known cases:
   * 1. Display a clamp if this work package is a parent element
   */
  checkForSpecialDisplaySituations(renderInfo:RenderInfo, bar:HTMLElement) {
    const wp = renderInfo.workPackage;

    // Cannot eddit the work package if it has children
    if (!wp.isLeaf) {
      bar.classList.add('-readonly');
    }

    // Display the parent as clamp-style when it has children in the table
    if (this.workPackageTimeline.inHierarchyMode &&
      hasChildrenInTable(wp, this.workPackageTimeline.workPackageTable)) {
      bar.classList.add('-clamp-style');
      bar.style.borderStyle = 'solid';
      bar.style.borderWidth = '2px';
      bar.style.borderColor = this.typeColor(wp);
      bar.style.borderBottom = 'none';
      bar.style.background = 'none';
    }
  }

  protected updateLabels(activeDragNDrop:boolean,
                         labels:WorkPackageCellLabels,
                         changeset:WorkPackageChangeset) {

    if (!this.TimezoneService) {
      this.TimezoneService = $injectNow('TimezoneService');
    }

    let startStr = changeset.value('startDate');
    let dueStr = changeset.value('dueDate');

    const subject:string = changeset.value('subject');
    const start:Moment | null = startStr ? moment(startStr) : null;
    const due:Moment | null = dueStr ? moment(dueStr) : null;

    if (!activeDragNDrop) {
      // normal display
      if (labels.labelLeft && start) {
        labels.labelLeft.textContent = this.TimezoneService.formattedDate(start);
      }
      if (labels.labelRight && due) {
        labels.labelRight.textContent = this.TimezoneService.formattedDate(due);
      }
      if (labels.labelFarRight) {
        labels.labelFarRight.textContent = subject;
      }
    } else {
      // active drag'n'drop
      if (labels.labelLeft && start) {
        labels.labelLeft.textContent = this.TimezoneService.formattedDate(start);
      }
      if (labels.labelRight && due) {
        labels.labelRight.textContent = this.TimezoneService.formattedDate(due);
      }
    }

    if (labels.labelLeft) {
      if (_.isEmpty(labels.labelLeft.textContent)) {
        labels.labelLeft.classList.remove('not-empty');
      } else {
        labels.labelLeft.classList.add('not-empty');
      }
    }
    if (labels.labelRight) {
      if (_.isEmpty(labels.labelRight.textContent)) {
        labels.labelRight.classList.remove('not-empty');
      } else {
        labels.labelRight.classList.add('not-empty');
      }
    }

  }

}
