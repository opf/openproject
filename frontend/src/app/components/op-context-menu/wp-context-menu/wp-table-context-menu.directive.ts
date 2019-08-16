import {Injector} from "@angular/core";
import {WorkPackageAction} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {WorkPackageViewContextMenu} from "core-components/op-context-menu/wp-context-menu/wp-view-context-menu.directive";

export class WorkPackageTableContextMenu extends WorkPackageViewContextMenu {

  constructor(protected injector:Injector,
              protected workPackageId:string,
              protected $element:JQuery,
              protected additionalPositionArgs:any = {},
              protected allowSplitScreenActions:boolean = true,
              protected table:WorkPackageTable) {
    super(injector, workPackageId, $element, additionalPositionArgs, allowSplitScreenActions);
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    switch (action.key) {
      case 'relation-precedes':
        this.table.timelineController.startAddRelationPredecessor(this.workPackage);
        break;

      case 'relation-follows':
        this.table.timelineController.startAddRelationFollower(this.workPackage);
        break;

      default:
        super.triggerContextMenuAction(action);
        break;
    }
  }
}
