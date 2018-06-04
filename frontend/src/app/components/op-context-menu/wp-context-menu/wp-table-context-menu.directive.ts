import {Injector} from "@angular/core";
import {
  WorkPackageAction,
  WorkPackageContextMenuHelperService
} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {States} from "core-components/states.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageTableSelection} from "core-components/wp-fast-table/state/wp-table-selection.service";
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";
import {OpContextMenuHandler} from "core-components/op-context-menu/op-context-menu-handler";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap
} from "core-components/op-context-menu/op-context-menu.types";
import {PERMITTED_CONTEXT_MENU_ACTIONS} from "core-components/op-context-menu/wp-context-menu/wp-static-context-menu-actions";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {WpDestroyModal} from "core-components/modals/wp-destroy-modal/wp-destroy.modal";
import {StateService} from "@uirouter/core";

export class OpWorkPackageContextMenu extends OpContextMenuHandler {

  private states = this.injector.get(States);
  private wpRelationsHierarchyService = this.injector.get(WorkPackageRelationsHierarchyService);
  private opModalService:OpModalService = this.injector.get(OpModalService);
  private $state:StateService = this.injector.get(StateService);
  private wpTableSelection = this.injector.get(WorkPackageTableSelection);
  private WorkPackageContextMenuHelper = this.injector.get(WorkPackageContextMenuHelperService);

  private workPackage = this.states.workPackages.get(this.workPackageId).value!;
  private selectedWorkPackages = this.getSelectedWorkPackages();
  private permittedActions = this.WorkPackageContextMenuHelper.getPermittedActions(
    this.selectedWorkPackages,
    PERMITTED_CONTEXT_MENU_ACTIONS
  );
  protected items = this.buildItems();

  constructor(readonly injector:Injector,
              readonly table:WorkPackageTable,
              readonly workPackageId:string,
              public $element:JQuery,
              public additionalPositionArgs:any = {}) {
    super(injector.get(OPContextMenuService))
  }

  public get locals():OpContextMenuLocalsMap {
    return { contextMenuId: 'work-package-context-menu', items: this.items};
  }

  public positionArgs(evt:JQueryEventObject) {
    let position = super.positionArgs(evt);
    _.assign(position, this.additionalPositionArgs);

    return position;
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    const link = action.link;

    switch (action.key) {
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
        window.location.href = link;
        break;
    }
  }

  private deleteSelectedWorkPackages() {
    var selected = this.getSelectedWorkPackages();
    this.opModalService.show(WpDestroyModal, {workPackages: selected});
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
        class: undefined as string|undefined,
        disabled: false,
        linkText: action.text,
        href: action.href,
        icon: action.icon != null ? action.icon : `icon-${action.key}`,
        onClick: ($event:JQueryEventObject) => {
          if (action.href && LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.triggerContextMenuAction(action)
          return true;
        }
      };
    });

    if (!this.workPackage.isNew) {
      items.unshift(
        {
          disabled: false,
          icon: 'icon-view-split',
          class: 'detailsViewMenuItem',
          href: this.$state.href('work-packages.list.details.overview', {workPackageId: this.workPackageId}),
          linkText: I18n.t('js.button_open_details'),
          onClick: ($event:JQueryEventObject) => {
            if (LinkHandling.isClickedWithModifier($event)) {
              return false;
            }

            this.$state.go(
              'work-packages.list.details.overview',
              {workPackageId: this.workPackageId}
            );
            return true;
          }
        },
        {
          disabled: false,
          icon: 'icon-view-fullscreen',
          class: 'openFullScreenView',
          href: this.$state.href('work-packages.show', {workPackageId: this.workPackageId}),
          linkText: I18n.t('js.button_open_fullscreen'),
          onClick: ($event:JQueryEventObject) => {
            if (LinkHandling.isClickedWithModifier($event)) {
              return false;
            }

            this.$state.go(
              'work-packages.show',
              { workPackageId: this.workPackageId }
            );
            return true;
          }
        },
      )
    }

    return items;
  }
}
