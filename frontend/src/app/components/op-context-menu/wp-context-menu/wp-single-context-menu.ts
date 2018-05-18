import {Directive, ElementRef, Inject, Input} from "@angular/core";
import {WorkPackageAction} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {
  $stateToken,
  HookServiceToken,
  wpDestroyModalToken
} from "core-app/angular4-transition-utils";
import {LinkHandling} from "core-components/common/link-handling/link-handling";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {PERMITTED_CONTEXT_MENU_ACTIONS} from "core-components/op-context-menu/wp-context-menu/wp-static-context-menu-actions";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import {WorkPackageAuthorization} from "core-components/work-packages/work-package-authorization.service";
import {AuthorisationService} from "core-components/common/model-auth/model-auth.service";
import {StateService} from "@uirouter/core";

@Directive({
  selector: '[wpSingleContextMenu]'
})
export class WorkPackageSingleContextMenuDirective extends OpContextMenuTrigger {
  @Input('wpSingleContextMenu-workPackage') public workPackage:WorkPackageResource;

  constructor(@Inject(HookServiceToken) readonly HookService:any,
              @Inject(wpDestroyModalToken) readonly wpDestroyModal:any,
              @Inject($stateToken) readonly $state:StateService,
              readonly elementRef:ElementRef,
              readonly opContextMenuService:OPContextMenuService,
              readonly authorisationService:AuthorisationService) {
    super(elementRef, opContextMenuService);
  }

  protected open(evt:Event) {
    this.workPackage.project.$load().then(() => {
      this.authorisationService.initModelAuth('work_package', this.workPackage.$links);

      var authorization = new WorkPackageAuthorization(this.workPackage);
      const permittedActions = angular.extend(this.getPermittedActions(authorization),
        this.getPermittedPluginActions(authorization));

      this.buildItems(permittedActions);
      this.opContextMenu.show(this, evt);
    });
  }

  public triggerContextMenuAction(action:WorkPackageAction, key:string) {
    const link = action.link;

    switch (key) {
      case 'copy':
        this.$state.go('work-packages.copy', {copiedFromWorkPackageId: this.workPackage.id});
        break;
      case 'delete':
        this.wpDestroyModal.activate({workPackages: [this.workPackage]});
        break;

      default:
        window.location.href = link;
        break;
    }
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:Event) {
    return {
      my: 'right top',
      at: 'right bottom',
      of: this.$element
    };
  }

  private getPermittedActions(authorization:WorkPackageAuthorization) {
    return authorization.permittedActionsWithLinks(PERMITTED_CONTEXT_MENU_ACTIONS);
  }

  private getPermittedPluginActions(authorization:WorkPackageAuthorization) {
    var pluginActions:WorkPackageAction[] = [];
    angular.forEach(this.HookService.call('workPackageDetailsMoreMenu'), function (action) {
      pluginActions = pluginActions.concat(action);
    });

    return authorization.permittedActionsWithLinks(pluginActions);
  }

  protected buildItems(permittedActions:WorkPackageAction[]) {
    this.items = permittedActions.map((action:WorkPackageAction) => {
      const key = action.icon!;
      return {
        disabled: false,
        linkText: I18n.t('js.button_' + key),
        href: action.link,
        icon: `icon-${key}`,
        onClick: ($event:JQueryEventObject) => {
          if (action.link && LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.triggerContextMenuAction(action, key);
          return true;
        }
      };
    });
  }
}
