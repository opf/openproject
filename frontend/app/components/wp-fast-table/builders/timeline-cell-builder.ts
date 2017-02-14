import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageTimelineCell} from '../../wp-table/timeline/wp-timeline-cell';
import {State} from '../../../helpers/reactive-fassade';
import {UiStateLinkBuilder} from './ui-state-link-builder';
import {WorkPackageTimelineTableController} from '../../wp-table/timeline/wp-timeline-container.directive';
import {States} from '../../states.service';
import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from './../../wp-display/wp-display-field/wp-display-field.module';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
export const timelineCellClassName = 'wp-timeline-cell';
export const timelineCollapsedClassName = '-collapsed';

export class TimelineCellBuilder {

  public states:States;
  public wpCacheService:WorkPackageCacheService;

  constructor() {
    injectorBridge(this);
  }

  public get isVisible():boolean {
    return this.states.table.timelineVisible.getCurrentValue() || false;
  }

  public get timelineInstance():WorkPackageTimelineTableController {
    return this.states.timeline.getCurrentValue();
  }

  public build(workPackage:WorkPackageResource, row:HTMLElement):void {
    const td = document.createElement('td');
    td.classList.add(timelineCellClassName, '-max');

    if (!this.isVisible) {
      td.classList.add(timelineCollapsedClassName);
    }

    this.buildTimelineCell(td, workPackage);
    row.appendChild(td);
  }

  public buildTimelineCell(cell:HTMLElement, workPackage:WorkPackageResource):void {
    // required data for timeline cell
    const timelineCell = new WorkPackageTimelineCell(
      this.timelineInstance,
      this.wpCacheService,
      this.states,
      workPackage.id,
      cell
    );

    // show timeline cell
    timelineCell.activate();

    // remove timeline cell on scope destroy
    this.states.table.stopAllSubscriptions.take(1).subscribe(() => {
      timelineCell.deactivate();
    });
  }
}

TimelineCellBuilder.$inject = ['states', 'wpCacheService'];
