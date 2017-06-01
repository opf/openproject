import {WorkPackageTable} from '../../wp-fast-table';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../../../states.service';
import {WorkPackageTableTimelineService} from '../../state/wp-table-timeline.service';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import {commonRowClassName} from '../rows/single-row-builder';

export const timelineCellClassName = 'wp-timeline-cell';

export function timelineRowId(id:string) {
  return `wp-timeline-row-${id}`;
}

export class TimelineRowBuilder {
  public states:States;
  public wpTableTimeline:WorkPackageTableTimelineService;
  public wpCacheService:WorkPackageCacheService;

  constructor(protected workPackageTable:WorkPackageTable) {
    $injectFields(this, 'states', 'wpTableTimeline', 'wpCacheService');
  }

  public build(workPackage:WorkPackageResourceInterface|null,
               rowClassNames:string[] = []) {
    const cell = document.createElement('div');
    cell.classList.add(timelineCellClassName, commonRowClassName, ...rowClassNames);

    if (workPackage) {
      cell.id = timelineRowId(workPackage.id);
      cell.dataset['workPackageId'] = workPackage.id;
      cell.classList.add(`${commonRowClassName}-${workPackage.id}`);
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
}
