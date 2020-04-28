import {Directive, ElementRef, Injector, Input} from '@angular/core';
import {StateService} from '@uirouter/core';
import {LinkHandling} from 'core-app/modules/common/link-handling/link-handling';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HookService} from 'core-app/modules/plugins/hook-service';
import {WpDestroyModal} from 'core-components/modals/wp-destroy-modal/wp-destroy.modal';
import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {OpContextMenuItem} from 'core-components/op-context-menu/op-context-menu.types';
import {PERMITTED_CONTEXT_MENU_ACTIONS} from 'core-components/op-context-menu/wp-context-menu/wp-static-context-menu-actions';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {WorkPackageAuthorization} from 'core-components/work-packages/work-package-authorization.service';
import {WorkPackageAction} from 'core-components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {TimeEntryCreateService} from "core-app/modules/time_entries/create/create.service";

@Directive({
  selector: '[wpSingleContextMenu]'
})
export class WorkPackageSingleContextMenuDirective extends OpContextMenuTrigger {
  @Input('wpSingleContextMenu-workPackage') public workPackage:WorkPackageResource;

  @InjectField() public timeEntryCreateService:TimeEntryCreateService;

  constructor(readonly HookService:HookService,
              readonly $state:StateService,
              readonly injector:Injector,
              readonly PathHelper:PathHelperService,
              readonly elementRef:ElementRef,
              readonly opModalService:OpModalService,
              readonly opContextMenuService:OPContextMenuService,
              readonly authorisationService:AuthorisationService) {
    super(elementRef, opContextMenuService);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.workPackage.project.$load().then(() => {
      this.authorisationService.initModelAuth('work_package', this.workPackage.$links);

      var authorization = new WorkPackageAuthorization(this.workPackage, this.PathHelper, this.$state);
      const permittedActions = this.getPermittedActions(authorization);

      this.buildItems(permittedActions);
      this.opContextMenu.show(this, evt);
    });
  }

  public triggerContextMenuAction(action:WorkPackageAction, key:string) {
    const link = action.link;

    switch (key) {
      case 'copy':
        this.$state.go('work-packages.copy', { copiedFromWorkPackageId: this.workPackage.id });
        break;
      case 'delete':
        this.opModalService.show(WpDestroyModal, this.injector, { workPackages: [this.workPackage] });
        break;
      case 'log_time':
        this.timeEntryCreateService
          .create(moment(new Date()), this.workPackage, false)
          .catch(() => {
            // do nothing, the user closed without changes
          });
        break;

      default:
        window.location.href = link!;
        break;
    }
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    let additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom'
    };

    let position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  private getPermittedActions(authorization:WorkPackageAuthorization) {
    let actions:WorkPackageAction[] = authorization.permittedActionsWithLinks(PERMITTED_CONTEXT_MENU_ACTIONS);

    // Splice plugin actions onto the core actions
    _.each(this.getPermittedPluginActions(authorization), (action:WorkPackageAction) => {
      let index = action.indexBy ? action.indexBy(actions) : actions.length;
      actions.splice(index, 0, action);
    });

    return actions;
  }

  private getPermittedPluginActions(authorization:WorkPackageAuthorization) {
    let actions:WorkPackageAction[] = this.HookService.call('workPackageSingleContextMenu');
    return authorization.permittedActionsWithLinks(actions);
  }

  protected buildItems(permittedActions:WorkPackageAction[]):OpContextMenuItem[] {
    const configureFormLink = this.workPackage.configureForm;

    this.items = permittedActions.map((action:WorkPackageAction) => {
      const key = action.key;
      return {
        disabled: false,
        linkText: I18n.t('js.button_' + key),
        href: action.link,
        icon: action.icon || `icon-${key}`,
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (action.link && LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.triggerContextMenuAction(action, key);
          return true;
        }
      };
    });

    if (configureFormLink) {
      this.items.push(
        {
          href: configureFormLink.href,
          icon: 'icon-settings3',
          linkText: I18n.t('js.button_configure-form'),
          onClick: () => false
        }
      );
    }

    return this.items;
  }
}
