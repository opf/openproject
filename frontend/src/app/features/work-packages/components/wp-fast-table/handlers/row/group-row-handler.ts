import { Injector } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { rowGroupClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';

export class GroupRowHandler implements TableEventHandler {
  // Injections
  @InjectField() public querySpace:IsolatedQuerySpace;

  @InjectField() public workPackageViewCollapsedGroupsService:WorkPackageViewCollapsedGroupsService;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT() {
    return 'click.table.groupheader';
  }

  public get SELECTOR() {
    return `.${rowGroupClassName} .expander`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tbody);
  }

  public handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent) {
    evt.preventDefault();
    evt.stopPropagation();

    const groupHeader = jQuery(evt.target).parents(`.${rowGroupClassName}`);
    const groupIdentifier = groupHeader.data('groupIdentifier');

    this.workPackageViewCollapsedGroupsService.toggleGroupCollapseState(groupIdentifier);
  }
}
