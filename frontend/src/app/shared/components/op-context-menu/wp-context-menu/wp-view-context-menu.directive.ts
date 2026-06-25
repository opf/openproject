import { Injector } from '@angular/core';
import {
  WorkPackageAction,
  WorkPackageContextMenuHelperService,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { States } from 'core-app/core/states/states.service';
import {
  WorkPackageRelationsHierarchyService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import {
  PERMITTED_CONTEXT_MENU_ACTIONS,
} from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-static-context-menu-actions';
import { StateService } from '@uirouter/core';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { isSemanticWorkPackageId } from 'core-app/shared/helpers/work-package-id-pattern';

import { Placement } from '@floating-ui/dom';

export interface PositionArgs { placement?:Placement, reference?:HTMLElement }

export class WorkPackageViewContextMenu extends OpContextMenuHandler {
  @LazyInject() protected states!:States;

  @LazyInject() protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService;

  @LazyInject() protected $state!:StateService;

  @LazyInject() protected wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() protected WorkPackageContextMenuHelper!:WorkPackageContextMenuHelperService;

  @LazyInject() protected currentProject:CurrentProjectService;

  @LazyInject() protected pathHelper:PathHelperService;

  @LazyInject() protected turboRequests:TurboRequestsService;

  protected workPackage = this.states.workPackages.get(this.workPackageId).value!;

  protected selectedWorkPackages = this.getSelectedWorkPackages();

  protected permittedActions = this.WorkPackageContextMenuHelper.getPermittedActions(
    this.selectedWorkPackages,
    PERMITTED_CONTEXT_MENU_ACTIONS,
    this.allowSplitScreenActions,
  );

  // Get the base route for the current route to ensure we always link correctly
  protected baseRoute = this.$state.current.data?.baseRoute ?? this.$state.current.name;

  // Whether we are running inside a uiRouter context (e.g. work packages list/board).
  // Calendar and Team Planner render without uiRouter and rely on Turbo navigation instead.
  protected get hasUiRouterContext():boolean {
    return this.$state.current.name !== '';
  }

  protected items = this.buildItems();

  private copyToClipboardService:CopyToClipboardService;

  protected reference:HTMLElement;

  constructor(
    public injector:Injector,
    protected workPackageId:string,
    protected element:HTMLElement,
    additionalPositionArgs:PositionArgs = {},
    protected allowSplitScreenActions = true,
  ) {
    super(injector.get(OPContextMenuService));
    this.copyToClipboardService = injector.get(CopyToClipboardService);

    if (typeof additionalPositionArgs.placement !== 'undefined') {
      this.placement = additionalPositionArgs.placement;
    }
    if (typeof additionalPositionArgs.reference !== 'undefined') {
      this.reference = additionalPositionArgs.reference;
    }
  }

  public get locals():OpContextMenuLocalsMap {
    return {
      contextMenuId: 'work-package-context-menu',
      label: I18n.t('js.label_work_package_context_menu'),
      items: this.items,
    };
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    const { link } = action;
    const id = this.workPackage.id!;

    switch (action.key) {
      case 'delete':
        this.deleteSelectedWorkPackages();
        break;

      case 'edit':
        this.editSelectedWorkPackages(link!);
        break;

      case 'duplicate':
        this.copySelectedWorkPackages(link!);
        break;

      case 'copy_link_to_clipboard': {
        const url = new URL(String(link), window.location.origin);
        this.copyToClipboardService.copy(url.toString());
        break;
      }
      case 'copy_numeric_id_to_clipboard':
        this.copyToClipboardService.copy(`${id}`);
        break;

      case 'copy_to_other_project':
        window.location.href = `${this.pathHelper.staticBase}/work_packages/move/new?copy=true&ids[]=${id}`;
        break;

      case 'relation-new-child':
        if (this.hasUiRouterContext) {
          this.wpRelationsHierarchyService.addNewChildWp(this.baseRoute, this.workPackage);
        } else {
          const newChildPath = `${window.location.pathname.replace(/\/details\/.*$/, '')}/details/new`;
          const childParams = new URLSearchParams(window.location.search);
          childParams.set('parent_id', id);
          Turbo.visit(`${newChildPath}?${childParams.toString()}`, { frame: 'content-bodyRight', action: 'advance' });
        }
        break;

      case 'log_time':
        this.logTimeForSelectedWorkPackage();
        break;

      case 'generate_pdf':
        void this.turboRequests.requestStream(String(link));
        break;

      case 'relations':
        if (this.hasUiRouterContext) {
          void this.$state.go(
            `${splitViewRoute(this.$state)}.tabs`,
            { workPackageId: this.workPackage.displayId, tabIdentifier: 'relations' },
          );
        } else {
          const relationsPath = `${window.location.pathname.replace(/\/details\/.*$/, '')}/details/${this.workPackage.displayId}${window.location.search}`;
          Turbo.visit(relationsPath, { frame: 'content-bodyRight', action: 'advance' });
        }
        break;

      default:
        window.location.href = link!;
        break;
    }
  }

  private deleteSelectedWorkPackages() {
    const selected = this.getSelectedWorkPackages();
    const ids = selected.map((wp) => wp.id).filter((id) => id !== null);
    const backUrl = this.$state.href(this.baseRoute as string) || this.pathHelper.workPackagesPath(this.currentProject.identifier ?? null);
    void this.turboRequests.request(this.pathHelper.workPackagesBulkDeleteDialogPath(ids, backUrl), { method: 'GET' });
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

    if (selected[0].id) {
      window.location.href = this.pathHelper.workPackageCopyPath(selected[0].project.id, selected[0].id);
    }
  }

  private logTimeForSelectedWorkPackage() {
    void this.turboRequests.request(this.pathHelper.timeEntryWorkPackageDialog(this.workPackage.id!), { method: 'GET' });
  }

  private getSelectedWorkPackages() {
    const selectedWorkPackages = this.wpTableSelection.getSelectedWorkPackages();

    if (selectedWorkPackages.length === 0) {
      return [this.workPackage];
    }

    if (!selectedWorkPackages.includes(this.workPackage)) {
      selectedWorkPackages.push(this.workPackage);
    }

    return selectedWorkPackages;
  }

  protected buildItems():OpContextMenuItem[] {
    const selected = this.getSelectedWorkPackages();

    // Copying the numeric ID is only useful in semantic mode, where the
    // displayed identifier (e.g. "PROJ-42") is not the numeric ID itself.
    const visibleActions = this.permittedActions.filter((action) => (
      action.key !== 'copy_numeric_id_to_clipboard'
      || isSemanticWorkPackageId(this.workPackage.displayId)
    ));

    const items = visibleActions.map((action:WorkPackageAction) => ({
      class: undefined as string | undefined,
      disabled: false,
      linkText: action.text,
      href: action.href,
      icon: action.icon != null ? action.icon : `icon-${action.key}`,
      onClick: (event:MouseEvent) => {
        if (action.href && isClickedWithModifier(event)) {
          return false;
        }

        this.triggerContextMenuAction(action);
        return true;
      },
    }));

    if (selected.length === 1 && !isNewResource(this.workPackage)) {
      const projectIdentifier = this.currentProject.identifier;
      const link = this.pathHelper.genericWorkPackagePath(projectIdentifier, this.workPackage.displayId) + window.location.search;

      items.unshift({
        disabled: false,
        icon: 'icon-view-fullscreen',
        class: 'openFullScreenView',
        href: link,
        linkText: I18n.t('js.button_open_fullscreen'),
        onClick: (event) => {
          if (isClickedWithModifier(event)) {
            return false;
          }

          Turbo.visit(link, { action: 'advance' });

          return true;
        },
      });

      if (selected.length === 1 && this.allowSplitScreenActions) {
        const splitViewHref = this.hasUiRouterContext
          ? this.$state.href(
            `${splitViewRoute(this.$state)}.tabs`,
            { workPackageId: this.workPackage.displayId, tabIdentifier: 'overview' },
          )
          : `${window.location.pathname.replace(/\/details\/.*$/, '')}/details/${this.workPackage.displayId}${window.location.search}`;

        items.unshift({
          disabled: false,
          icon: 'icon-view-split',
          class: 'detailsViewMenuItem',
          href: splitViewHref,
          linkText: I18n.t('js.button_open_details'),
          onClick: (event) => {
            if (isClickedWithModifier(event)) {
              return false;
            }

            if (this.hasUiRouterContext) {
              this.$state.go(
                `${splitViewRoute(this.$state)}.tabs`,
                { workPackageId: this.workPackage.displayId, tabIdentifier: 'overview' },
              );
            } else {
              Turbo.visit(splitViewHref, { frame: 'content-bodyRight', action: 'advance' });
            }
            return true;
          },
        });
      }
    }

    return items;
  }
}
