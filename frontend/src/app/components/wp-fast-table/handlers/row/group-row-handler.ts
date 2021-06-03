import { Injector } from '@angular/core';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { IsolatedQuerySpace } from 'core-app/modules/work_packages/query-space/isolated-query-space';
import { rowGroupClassName } from 'core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { InjectField } from 'core-app/helpers/angular/inject-field.decorator';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';

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
