import { Injector } from '@angular/core';
import { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { PositionArgs, WorkPackageViewContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { WorkPackageViewHierarchyIdentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';

export class WorkPackageTableContextMenu extends WorkPackageViewContextMenu {
  @LazyInject() wpViewIndentation:WorkPackageViewHierarchyIdentationService;

  constructor(public injector:Injector,
    protected workPackageId:string,
    protected element:HTMLElement,
    additionalPositionArgs:PositionArgs,
    protected table:WorkPackageTable) {
    super(injector, workPackageId, element, additionalPositionArgs, true);
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    switch (action.key) {
      case 'relation-precedes':
        this.table.timelineController.startAddRelationPredecessor(this.workPackage);
        break;

      case 'relation-follows':
        this.table.timelineController.startAddRelationFollower(this.workPackage);
        break;

      case 'hierarchy-indent':
        this.wpViewIndentation.indent(this.workPackage);
        break;

      case 'hierarchy-outdent':
        this.wpViewIndentation.outdent(this.workPackage);
        break;

      default:
        super.triggerContextMenuAction(action);
        break;
    }
  }
}
