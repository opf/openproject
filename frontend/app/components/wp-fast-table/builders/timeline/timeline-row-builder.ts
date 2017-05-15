import {WorkPackageTable} from '../../wp-fast-table';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../../../states.service';
import {WorkPackageTableTimelineService} from '../../state/wp-table-timeline.service';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import {WorkPackageTimelineCell} from '../../../wp-table/timeline/wp-timeline-cell';
import {commonRowClassName} from '../rows/single-row-builder';
import {Observable} from 'rxjs';

export const timelineCellClassName = 'wp-timeline-cell';

export class TimelineRowBuilder {
  public states:States;
  public wpTableTimeline:WorkPackageTableTimelineService;
  public wpCacheService:WorkPackageCacheService;

  constructor(protected stopExisting$:Observable<void>, protected workPackageTable:WorkPackageTable) {
    $injectFields(this, 'states', 'wpTableTimeline', 'wpCacheService');
  }

  public build(workPackage:WorkPackageResourceInterface|null,
               rowClassNames:string[] = []) {
    const cell = document.createElement('div');
    cell.classList.add(timelineCellClassName, commonRowClassName, ...rowClassNames);

    if (workPackage) {
      cell.id = `wp-timeline-row-${workPackage.id}`;
      cell.dataset['workPackageId'] = workPackage.id;
      cell.classList.add(`${commonRowClassName}-${workPackage.id}`);

      // TODO skip if inserting rows that are not work packages
      // We may either need to extend the timelinecell to handle these cases
      // or alter the rendering of (e.g.,) relations to draw over these rows
      this.buildTimelineCell(cell, workPackage);
    }

    return cell;
  }

  /**
   * Build and insert a timeline row for the given work package using the additional classes.
   * @param workPackage
   * @param timelineBody
   * @param rowClasses
   */
  public insert(workPackage:WorkPackageResourceInterface | null,
                timelineBody:DocumentFragment | HTMLElement,
                rowClasses:string[] = []) {
    timelineBody.appendChild(this.build(workPackage, rowClasses));
  }

  public buildTimelineCell(cell:HTMLElement, workPackage:WorkPackageResourceInterface):void {
    // required data for timeline cell
    const timelineCell = new WorkPackageTimelineCell(
      this.workPackageTable.timelineController,
      workPackage.id,
      cell
    );

    // show timeline cell
    timelineCell.activate();
    this.stopExisting$.take(1)
      .subscribe(() => {
        timelineCell.deactivate();
      });
  }
}
