import {Injector} from "@angular/core";
import {
  WorkPackageAction,
  WorkPackageContextMenuHelperService
} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {States} from "core-components/states.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {$stateToken, wpDestroyModalToken} from "core-app/angular4-transition-utils";
import {WorkPackageTableSelection} from "core-components/wp-fast-table/state/wp-table-selection.service";
import {LinkHandling} from "core-components/common/link-handling/link-handling";
import {OpContextMenuHandler} from "core-components/op-context-menu/op-context-menu-handler";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap
} from "core-components/op-context-menu/op-context-menu.types";

export class OpWorkPackageContextMenu extends OpContextMenuHandler {

  static PERMITTED_CONTEXT_MENU_ACTIONS = [
    {
      icon: 'log_time',
      link: 'logTime'
    },
    {
      icon: 'move',
      link: 'move'
    },
    {
      icon: 'copy',
      link: 'copy'
    },
    {
      icon: 'delete',
      link: 'delete'
    },
    {
      icon: 'export-pdf',
      link: 'pdf'
    },
    {
      icon: 'export-atom',
      link: 'atom'
    }
  ];

  private states = this.injector.get(States);
  private wpRelationsHierarchyService = this.injector.get(WorkPackageRelationsHierarchyService);
  private wpDestroyModal = this.injector.get(wpDestroyModalToken);
  private $state = this.injector.get($stateToken);
  private wpTableSelection = this.injector.get(WorkPackageTableSelection);
  private WorkPackageContextMenuHelper = this.injector.get(WorkPackageContextMenuHelperService);

  private workPackage = this.states.workPackages.get(this.workPackageId).value!;
  private permittedActions = this.WorkPackageContextMenuHelper.getPermittedActions(
    this.getSelectedWorkPackages(),
    OpWorkPackageContextMenu.PERMITTED_CONTEXT_MENU_ACTIONS
  );
  protected items = this.buildItems();

  constructor(readonly injector:Injector,
              readonly table:WorkPackageTable,
              readonly workPackageId:string,
              public $element:JQuery) {
    super(injector.get(OPContextMenuService))
  }

  public get locals():OpContextMenuLocalsMap {
    return {items: this.items}
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    const link = action.link;

    switch (action.icon) {
      case 'delete':
        this.deleteSelectedWorkPackages();
        break;

      case 'edit':
        this.editSelectedWorkPackages(link);
        break;

      case 'copy':
        this.copySelectedWorkPackages(link);
        break;

      case 'relation-precedes':
        this.table.timelineController.startAddRelationPredecessor(this.workPackage);
        break;

      case 'relation-follows':
        this.table.timelineController.startAddRelationFollower(this.workPackage);
        break;

      case 'relation-new-child':
        this.wpRelationsHierarchyService.addNewChildWp(this.workPackage);
        break;

      default:
        window.location.href = link!;
        break;
    }
  }

  private deleteSelectedWorkPackages() {
    var selected = this.getSelectedWorkPackages();
    this.wpDestroyModal.activate({workPackages: selected});
  }

  private editSelectedWorkPackages(link:any) {
    var selected = this.getSelectedWorkPackages();

    if (selected.length > 1) {
      window.location.href = link;
      return;
    }
  }

  private copySelectedWorkPackages(link:any) {
    var selected = this.getSelectedWorkPackages();

    if (selected.length > 1) {
      window.location.href = link;
      return;
    }

    var params = {
      copiedFromWorkPackageId: selected[0].id
    };

    this.$state.go('work-packages.list.copy', params);
  }

  private getSelectedWorkPackages() {
    let selectedWorkPackages = this.wpTableSelection.getSelectedWorkPackages();

    if (selectedWorkPackages.length === 0) {
      return [this.workPackage];
    }

    if (selectedWorkPackages.indexOf(this.workPackage) === -1) {
      selectedWorkPackages.push(this.workPackage);
    }

    return selectedWorkPackages;
  }

  protected buildItems():OpContextMenuItem[] {
    let items = this.permittedActions.map((action:WorkPackageAction) => {
      return {
        disabled: false,
        linkText: action.text,
        href: action.href,
        icon: action.icon ? `icon-${action.icon}` : undefined,
        onClick: ($event:JQueryEventObject) => {
          if (action.href && LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.triggerContextMenuAction(action)
          return true;
        }
      }
    });

    return items;
  }
}
