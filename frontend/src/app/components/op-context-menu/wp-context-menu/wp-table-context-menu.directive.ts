import { Injector } from "@angular/core";
import { WorkPackageAction } from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import { WorkPackageTable } from "core-components/wp-fast-table/wp-fast-table";
import { WorkPackageViewContextMenu } from "core-components/op-context-menu/wp-context-menu/wp-view-context-menu.directive";
import { WorkPackageViewHierarchyIdentationService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export class WorkPackageTableContextMenu extends WorkPackageViewContextMenu {

  @InjectField() wpViewIndentation:WorkPackageViewHierarchyIdentationService;

  constructor(public injector:Injector,
              protected workPackageId:string,
              protected $element:JQuery,
              protected additionalPositionArgs:any = {},
              protected table:WorkPackageTable) {
    super(injector, workPackageId, $element, additionalPositionArgs, true);
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
