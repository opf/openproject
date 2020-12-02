import {Injector} from '@angular/core';
import {distinctUntilChanged, takeUntil} from 'rxjs/operators';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {WorkPackageViewCollapsedGroupsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service";

export class GroupFoldTransformer {

  @InjectField() public wpGroupFold:WorkPackageViewCollapsedGroupsService;
  @InjectField() public querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.wpGroupFold
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        distinctUntilChanged()
      )
      .subscribe(() => {
        table.redrawTableAndTimeline();
      });
  }
}
