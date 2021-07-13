import { Injector } from '@angular/core';
import { distinctUntilChanged, takeUntil } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';

export class GroupFoldTransformer {
  @InjectField() public workPackageViewCollapsedGroupsService:WorkPackageViewCollapsedGroupsService;

  @InjectField() public querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
    table:WorkPackageTable) {
    this.workPackageViewCollapsedGroupsService
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        distinctUntilChanged(),
      )
      .subscribe((groupsCollapseEvent) => table.setGroupsCollapseState(groupsCollapseEvent.state));
  }
}
