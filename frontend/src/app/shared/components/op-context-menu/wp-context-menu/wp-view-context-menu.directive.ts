import { Injector } from '@angular/core';
import {
  WorkPackageAction,
  WorkPackageContextMenuHelperService,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { PERMITTED_CONTEXT_MENU_ACTIONS } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-static-context-menu-actions';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { StateService } from '@uirouter/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { TimeEntryCreateService } from 'core-app/shared/components/time_entries/create/create.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { WpDestroyModalComponent } from 'core-app/shared/components/modals/wp-destroy-modal/wp-destroy.modal';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import * as moment from 'moment-timezone';

export class WorkPackageViewContextMenu extends OpContextMenuHandler {
  @InjectField() protected states!:States;

  @InjectField() protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService;

  @InjectField() protected opModalService:OpModalService;

  @InjectField() protected $state!:StateService;

  @InjectField() protected wpTableSelection:WorkPackageViewSelectionService;

  @InjectField() protected WorkPackageContextMenuHelper!:WorkPackageContextMenuHelperService;

  @InjectField() protected timeEntryCreateService:TimeEntryCreateService;

  @InjectField() protected pathHelper:PathHelperService;

  protected workPackage = this.states.workPackages.get(this.workPackageId).value!;

  protected selectedWorkPackages = this.getSelectedWorkPackages();

  protected permittedActions = this.WorkPackageContextMenuHelper.getPermittedActions(
    this.selectedWorkPackages,
    PERMITTED_CONTEXT_MENU_ACTIONS,
    this.allowSplitScreenActions,
  );

  // Get the base route for the current route to ensure we always link correctly
  protected baseRoute = this.$state.current.data.baseRoute || this.$state.current.name;

  protected items = this.buildItems();

  private copyToClipboardService:CopyToClipboardService;

  constructor(
    public injector:Injector,
    protected workPackageId:string,
    protected $element:JQuery,
    protected additionalPositionArgs:any = {},
    protected allowSplitScreenActions:boolean = true,
  ) {
    super(injector.get(OPContextMenuService));
    this.copyToClipboardService = injector.get(CopyToClipboardService);
  }

  public get locals():OpContextMenuLocalsMap {
    return {
      contextMenuId: 'work-package-context-menu',
      label: I18n.t('js.label_work_package_context_menu'),
      items: this.items,
    };
  }

  public positionArgs(evt:JQuery.TriggeredEvent) {
    const position = super.positionArgs(evt);
    _.assign(position, this.additionalPositionArgs);

    return position;
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    const { link } = action;
    const id = this.workPackage.id as string;

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

      case 'copy_link_to_clipboard': {
        const url = new URL(String(link), window.location.origin);
        this.copyToClipboardService.copy(url.toString());
        break;
      }
      case 'copy_to_other_project':
        window.location.href = `${this.pathHelper.staticBase}/work_packages/move/new?copy=true&ids[]=${id}`;
        break;

      case 'relation-new-child':
        this.wpRelationsHierarchyService.addNewChildWp(this.baseRoute, this.workPackage);
        break;

      case 'log_time':
        this.logTimeForSelectedWorkPackage();
        break;
      case 'relations':
        void this.$state.go(
          `${splitViewRoute(this.$state)}.tabs`,
          { workPackageId: this.workPackageId, tabIdentifier: 'relations' },
        );
        break;

      default:
        window.location.href = link!;
        break;
    }
  }

  private deleteSelectedWorkPackages() {
    const selected = this.getSelectedWorkPackages();
    this.opModalService.show(WpDestroyModalComponent, this.injector, { workPackages: selected });
  }

  private editSelectedWorkPackages(link:any) {
    const selected = this.getSelectedWorkPackages();

    if (selected.length > 1) {
      window.location.href = link;
    }
  }

  private copySelectedWorkPackages(link:any) {
    const selected = this.getSelectedWorkPackages();

    if (selected.length > 1) {
      window.location.href = link;
      return;
    }

    const params = {
      copiedFromWorkPackageId: selected[0].id,
    };

    this.$state.go(`${this.baseRoute}.copy`, params);
  }

  private logTimeForSelectedWorkPackage() {
    this.timeEntryCreateService
      .create(moment(new Date()), this.workPackage)
      .catch(() => {
        // do nothing, the user closed without changes
      });
  }

  private getSelectedWorkPackages() {
    const selectedWorkPackages = this.wpTableSelection.getSelectedWorkPackages();

    if (selectedWorkPackages.length === 0) {
      return [this.workPackage];
    }

    if (selectedWorkPackages.indexOf(this.workPackage) === -1) {
      selectedWorkPackages.push(this.workPackage);
    }

    return selectedWorkPackages;
  }

  protected buildItems():OpContextMenuItem[] {
    const items = this.permittedActions.map((action:WorkPackageAction) => ({
      class: undefined as string|undefined,
      disabled: false,
      linkText: action.text,
      href: action.href,
      icon: action.icon != null ? action.icon : `icon-${action.key}`,
      onClick: ($event:JQuery.TriggeredEvent) => {
        if (action.href && isClickedWithModifier($event)) {
          return false;
        }

        this.triggerContextMenuAction(action);
        return true;
      },
    }));

    if (!isNewResource(this.workPackage)) {
      items.unshift({
        disabled: false,
        icon: 'icon-view-fullscreen',
        class: 'openFullScreenView',
        href: this.$state.href('work-packages.show', { workPackageId: this.workPackageId }),
        linkText: I18n.t('js.button_open_fullscreen'),
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (isClickedWithModifier($event)) {
            return false;
          }

          this.$state.go(
            'work-packages.show',
            { workPackageId: this.workPackageId },
          );
          return true;
        },
      });

      if (this.allowSplitScreenActions) {
        items.unshift({
          disabled: false,
          icon: 'icon-view-split',
          class: 'detailsViewMenuItem',
          href: this.$state.href(
            `${splitViewRoute(this.$state)}.tabs`,
            { workPackageId: this.workPackageId, tabIdentifier: 'overview' },
          ),
          linkText: I18n.t('js.button_open_details'),
          onClick: ($event:JQuery.TriggeredEvent) => {
            if (isClickedWithModifier($event)) {
              return false;
            }

            this.$state.go(
              `${splitViewRoute(this.$state)}.tabs`,
              { workPackageId: this.workPackageId, tabIdentifier: 'overview' },
            );
            return true;
          },
        });
      }
    }

    return items;
  }
}
