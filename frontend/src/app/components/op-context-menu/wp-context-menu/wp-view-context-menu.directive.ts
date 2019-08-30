import {Injector} from "@angular/core";
import {
  WorkPackageAction,
  WorkPackageContextMenuHelperService
} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {States} from "core-components/states.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
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

export class WorkPackageViewContextMenu extends OpContextMenuHandler {

  protected states = this.injector.get(States);
  protected wpRelationsHierarchyService = this.injector.get(WorkPackageRelationsHierarchyService);
  protected opModalService:OpModalService = this.injector.get(OpModalService);
  protected $state:StateService = this.injector.get(StateService);
  protected wpTableSelection = this.injector.get(WorkPackageViewSelectionService);
  protected WorkPackageContextMenuHelper = this.injector.get(WorkPackageContextMenuHelperService);

  protected workPackage = this.states.workPackages.get(this.workPackageId).value!;
  protected selectedWorkPackages = this.getSelectedWorkPackages();
  protected permittedActions = this.WorkPackageContextMenuHelper.getPermittedActions(
    this.selectedWorkPackages,
    PERMITTED_CONTEXT_MENU_ACTIONS,
    this.allowSplitScreenActions
  );
  protected items = this.buildItems();

  constructor(protected injector:Injector,
              protected workPackageId:string,
              protected $element:JQuery,
              protected additionalPositionArgs:any = {},
              protected allowSplitScreenActions:boolean = true) {
    super(injector.get(OPContextMenuService));
  }

  public get locals():OpContextMenuLocalsMap {
    return { contextMenuId: 'work-package-context-menu', items: this.items};
  }

  public positionArgs(evt:JQuery.TriggeredEvent) {
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
        this.editSelectedWorkPackages(link!);
        break;

      case 'copy':
        this.copySelectedWorkPackages(link!);
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
    let selected = this.getSelectedWorkPackages();
    this.opModalService.show(WpDestroyModal, this.injector, { workPackages: selected });
  }

  private editSelectedWorkPackages(link:any) {
    let selected = this.getSelectedWorkPackages();

    if (selected.length > 1) {
      window.location.href = link;
      return;
    }
  }

  private copySelectedWorkPackages(link:any) {
    let selected = this.getSelectedWorkPackages();

    if (selected.length > 1) {
      window.location.href = link;
      return;
    }

    let params = {
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
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (action.href && LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.triggerContextMenuAction(action);
          return true;
        }
      };
    });


    if (!this.workPackage.isNew) {
      items.unshift({
        disabled: false,
        icon: 'icon-view-fullscreen',
        class: 'openFullScreenView',
        href: this.$state.href('work-packages.show', {workPackageId: this.workPackageId}),
        linkText: I18n.t('js.button_open_fullscreen'),
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.$state.go(
            'work-packages.show',
            { workPackageId: this.workPackageId }
          );
          return true;
        }
      });

      if (this.allowSplitScreenActions) {
        items.unshift({
          disabled: false,
          icon: 'icon-view-split',
          class: 'detailsViewMenuItem',
          href: this.$state.href('work-packages.list.details.overview', {workPackageId: this.workPackageId}),
          linkText: I18n.t('js.button_open_details'),
          onClick: ($event:JQuery.TriggeredEvent) => {
            if (LinkHandling.isClickedWithModifier($event)) {
              return false;
            }

            this.$state.go(
              'work-packages.list.details.overview',
              {workPackageId: this.workPackageId}
            );
            return true;
          }
        });
      }
    }

    return items;
  }
}
