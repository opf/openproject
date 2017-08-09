import * as moment from 'moment';
import {$injectNow} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {calculatePositionValueForDayCountingPx, RenderInfo, timelineElementCssClass} from '../wp-timeline';
import {TimelineCellRenderer} from './timeline-cell-renderer';
import {
  classNameFarRightLabel,
  classNameLeftLabel, classNameRightContainer, classNameRightLabel, classNameShowOnHover,
  WorkPackageCellLabels
} from './wp-timeline-cell';
import Moment = moment.Moment;
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';

interface CellMilestoneMovement {
  // Target value to move milestone to
  date?:moment.Moment;
}

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {
  public get type():string {
    return 'milestone';
  }

  public isEmpty(wp:WorkPackageResourceInterface) {
    const date = moment(wp.date as any);
    const noDateValue = _.isNaN(date.valueOf());
    return noDateValue;
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
   * For generic work packages, assigns start and due date.
   *
   */
  public assignDateValues(changeset:WorkPackageChangeset,
                          labels:WorkPackageCellLabels,
                          dates:CellMilestoneMovement) {

    this.assignDate(changeset, 'date', dates.date!);
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
    let dates:CellMilestoneMovement = {};

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
    this.forceCursor('ew-resize');

    if (dateForCreate) {
      renderInfo.changeset.setValue('date', dateForCreate);
      direction = 'create';
      return direction;
    }

    this.updateLabels(true, labels, renderInfo.changeset);

    return direction;
  }

  public update(element:HTMLDivElement, renderInfo:RenderInfo): boolean {
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
    diamond.style.backgroundColor = this.typeColor(renderInfo.workPackage);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, 'days');
    element.style.left = calculatePositionValueForDayCountingPx(viewParams, offsetStart) + 'px';

    this.checkForActiveSelectionMode(renderInfo, diamond);

    return true;
  }

  getMarginLeftOfLeftSide(renderInfo:RenderInfo):number {
    const changeset = renderInfo.changeset;
    let start = moment(changeset.value('date') as any);
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

    const labels = new WorkPackageCellLabels(null, labelLeft, labelRight, labelFarRight);
    this.updateLabels(false, labels, renderInfo.changeset);

    return labels;
  }

  protected updateLabels(activeDragNDrop:boolean,
                         labels:WorkPackageCellLabels,
                         changeset:WorkPackageChangeset) {

    if (!this.TimezoneService) {
      this.TimezoneService = $injectNow('TimezoneService');
    }

    const subject:string = changeset.value('subject');
    const dateStr = changeset.value('date');
    const date:Moment | null = dateStr ? moment(dateStr) : null;

    if (!activeDragNDrop) {
      // normal display
      if (labels.labelRight && date) {
        labels.labelRight.textContent = this.TimezoneService.formattedDate(date);
      }
      if (labels.labelFarRight) {
        labels.labelFarRight.textContent = subject;
      }
    } else {
      // active drag'n'drop
      if (labels.labelRight && date) {
        labels.labelRight.textContent = this.TimezoneService.formattedDate(date);
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
