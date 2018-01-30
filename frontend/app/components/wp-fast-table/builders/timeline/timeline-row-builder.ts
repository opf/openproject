import {Injector} from '@angular/core';
import {States} from '../../../states.service';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import {WorkPackageTableTimelineService} from '../../state/wp-table-timeline.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {commonRowClassName} from '../rows/single-row-builder';

export const timelineCellClassName = 'wp-timeline-cell';

export class TimelineRowBuilder {

  public states = this.injector.get(States);
  public wpTableTimeline = this.injector.get(WorkPackageTableTimelineService);
  public wpCacheService = this.injector.get(WorkPackageCacheService);

  constructor(public readonly injector:Injector,
              protected workPackageTable:WorkPackageTable) {
  }

  public build(workPackageId:string | null) {
    const cell = document.createElement('div');
    cell.classList.add(timelineCellClassName, commonRowClassName);

    if (workPackageId) {
      cell.dataset['workPackageId'] = workPackageId;
    }

    return cell;
  }

  /**
   * Build and insert a timeline row for the given work package using the additional classes.
   * @param workPackage
   * @param timelineBody
   * @param rowClasses
   */
  public insert(workPackageId:string | null,
                timelineBody:DocumentFragment | HTMLElement,
                rowClasses:string[] = []) {

    const cell = this.build(workPackageId);
    cell.classList.add(...rowClasses);

    timelineBody.appendChild(cell);
  }
}
