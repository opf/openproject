import { AfterViewInit, Directive, ElementRef, inject, Injector, Input, OnDestroy } from '@angular/core';
import { StateService } from '@uirouter/core';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HookService } from 'core-app/features/plugins/hook-service';
import {
  OpContextMenuTrigger,
} from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import {
  PERMITTED_CONTEXT_MENU_ACTIONS,
} from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-static-context-menu-actions';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import {
  WorkPackageAction,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WorkPackageAuthorization } from 'core-app/features/work-packages/services/work-package-authorization.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryTimerService } from 'core-app/shared/components/time_entries/services/time-entry-timer.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { DeviceService } from 'core-app/core/browser/device.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { isSemanticWorkPackageId } from 'core-app/shared/helpers/work-package-id-pattern';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpSingleContextMenu]',
  standalone: false,
})
export class WorkPackageSingleContextMenuDirective extends OpContextMenuTrigger implements AfterViewInit, OnDestroy {
  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('wpSingleContextMenu-workPackage') public workPackage:WorkPackageResource;

  private currentTimer:TimeEntryResource|null = null;

  readonly HookService = inject(HookService);
  readonly $state = inject(StateService);
  readonly injector = inject(Injector);
  readonly PathHelper = inject(PathHelperService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly turboRequests = inject(TurboRequestsService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly authorisationService = inject(AuthorisationService);
  readonly currentProject = inject(CurrentProjectService);
  readonly timeEntryService = inject(TimeEntryTimerService);
  protected copyToClipboardService = inject(CopyToClipboardService);
  protected deviceService = inject(DeviceService);

  private closeDialogHandler:EventListener = this.handleTimeEntryDialogClose.bind(this);

  override readonly placement = 'bottom-end';

  ngAfterViewInit():void {
    super.ngAfterViewInit();
    document.addEventListener('dialog:close', this.closeDialogHandler);

    this.timeEntryService.activeTimer$.subscribe((timer) => {
      this.currentTimer = timer;
    });
  }

  ngOnDestroy():void {
    document.removeEventListener('dialog:close', this.closeDialogHandler);
  }

  protected open(evt:Event) {
    this.workPackage.project.$load().then(() => {
      this.authorisationService.initModelAuth('work_package', this.workPackage.$links);

      const authorization = new WorkPackageAuthorization(this.workPackage, this.PathHelper, this.$state);
      const permittedActions = this.getPermittedActions(authorization);

      this.buildItems(permittedActions);
      this.opContextMenu.show(this, evt);
    });
  }

  public triggerContextMenuAction(action:WorkPackageAction, key:string) {
    const { link } = action;

    switch (key) {
      case 'copy_to_other_project':
        window.location.href = `${this.PathHelper.staticBase}/work_packages/move/new?copy=true&ids[]=${this.workPackage.id!}`;
        break;
      case 'start_timer':
        this.timeEntryService.start(this.workPackage);
        break;
      case 'stop_timer':
        void this.timeEntryService.stop();
        break;
      case 'copy':
        if (this.workPackage.id) {
          window.location.href = `${this.PathHelper.workPackageCopyPath(this.workPackage.project.identifier, this.workPackage.id)}`;
        }
        break;
      case 'delete': {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        const currentBaseRoute = this.$state.current.data?.baseRoute as string | undefined;
        const backUrl = currentBaseRoute
          ? this.$state.href(currentBaseRoute)
          : this.PathHelper.workPackagesPath(this.currentProject.identifier ?? null);
        void this.turboRequests.request(
          this.PathHelper.workPackagesBulkDeleteDialogPath([this.workPackage.id!], backUrl),
          { method: 'GET' },
        );
        break;
      }
      case 'log_time':
        void this.turboRequests.request(this.PathHelper.timeEntryWorkPackageDialog(this.workPackage.id!), { method: 'GET' });
        break;
      case 'generate_pdf':
        void this.turboRequests.requestStream(link!);
        break;
      case 'copy_link_to_clipboard': {
        const url = new URL(String(link), window.location.origin);
        this.copyToClipboardService.copy(url.toString());
        break;
      }
      case 'copy_numeric_id_to_clipboard':
        this.copyToClipboardService.copy(`${this.workPackage.id!}`);
        break;
      default:
        window.location.href = link!;
        break;
    }
  }

  private activeForWorkPackage(entry:TimeEntryResource|null):boolean {
    return !!entry && entry.entity.href === this.workPackage.href;
  }

  private getTimerAction():WorkPackageAction {
    if (this.activeForWorkPackage(this.currentTimer)) {
      return {
        key: 'stop_timer',
        icon: 'icon-time-tracking-stop',
        link: 'logTime',
        hidden: !this.deviceService.isSmallDesktop,
      };
    } else {
      return {
        key: 'start_timer',
        icon: 'icon-time-tracking-start',
        link: 'logTime',
        hidden: !this.deviceService.isSmallDesktop,
      };
    }
  }

  private getPermittedActions(authorization:WorkPackageAuthorization) {
    let actions:WorkPackageAction[] = authorization.permittedActionsWithLinks(PERMITTED_CONTEXT_MENU_ACTIONS);

    // Add the available actions on timers
    actions = this.addTimerAction(actions);

    // Copying the numeric ID is only useful in semantic mode, where the
    // displayed identifier (e.g. "PROJ-42") is not the numeric ID itself.
    const copyIdAction = actions.find((action) => action.key === 'copy_numeric_id_to_clipboard');
    if (copyIdAction) {
      copyIdAction.hidden = !isSemanticWorkPackageId(this.workPackage.displayId);
    }

    // Splice plugin actions onto the core actions
    _.each(this.getPermittedPluginActions(authorization), (action:WorkPackageAction) => {
      const index = action.indexBy ? action.indexBy(actions) : actions.length;
      actions.splice(index, 0, action);
    });

    return actions;
  }

  private addTimerAction(actions:WorkPackageAction[]) {
    const action = this.getTimerAction();
    const timeIndex = actions.findIndex((action) => action.key === 'log_time');

    if (timeIndex !== -1) {
      actions.splice(timeIndex + 1, 0, action);
    }

    return actions;
  }

  private getPermittedPluginActions(authorization:WorkPackageAuthorization) {
    const actions:WorkPackageAction[] = this.HookService.call('workPackageSingleContextMenu');
    return authorization.permittedActionsWithLinks(actions);
  }

  protected buildItems(permittedActions:WorkPackageAction[]):OpContextMenuItem[] {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const configureFormLink = this.workPackage.configureForm;

    this.items = permittedActions.map((action:WorkPackageAction) => {
      const { key } = action;

      // "Copy numeric ID" copies a plain value rather than navigating anywhere.
      // Rendering it as a link would show a misleading link preview on hover and
      // make the clipboard copy originate from an anchor, so render it as a
      // button (no href).
      const href = key === 'copy_numeric_id_to_clipboard' ? undefined : action.link;

      return {
        disabled: false,
        hidden: action.hidden === true,
        linkText: I18n.t(`js.button_${key}`),
        href,
        icon: action.icon || `icon-${key}`,
        onClick: (event:MouseEvent) => {
          if (href && isClickedWithModifier(event)) {
            return false;
          }

          this.triggerContextMenuAction(action, key);
          return true;
        },
      };
    });

    if (configureFormLink) {
      this.items.push(
        {
          href: configureFormLink.href,
          icon: 'icon-settings3',
          linkText: I18n.t('js.button_configure-form'),
          onClick: () => false,
        },
      );
    }

    return this.items;
  }

  private handleTimeEntryDialogClose(event:CustomEvent):void {
    const { detail: { dialog, submitted } } = event as { detail:{ dialog:HTMLDialogElement, submitted:boolean } };

    if (dialog.id === 'time-entry-dialog' && submitted) {
      void this.apiV3Service
        .work_packages
        .id(this.workPackage.id!)
        .refresh();
    }
  }
}
