import {Injector} from "@angular/core";
import {HookService} from "core-app/modules/plugins/hook-service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {ConfirmDialogService} from "core-components/modals/confirm-dialog/confirm-dialog.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ExternalQueryConfigurationService} from "core-components/wp-table/external-configuration/external-query-configuration.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PasswordConfirmationModal} from "../../components/modals/request-for-confirmation/password-confirmation.modal";
import {OpModalService} from "../../components/op-modals/op-modal.service";
import {HelpTextDmService} from "../hal/dm-services/help-text-dm.service";
import {AttributeHelpTextsService} from "../common/help-texts/attribute-help-text.service";
import {AttributeHelpTextModal} from "../common/help-texts/attribute-help-text.modal";

/**
 * Plugin context bridge for plugins outside the CLI compiler context
 * in order to access services and parts of the core application
 */
export class OpenProjectPluginContext {

  private _knownHookNames = [
    'workPackageTableContextMenu',
    'workPackageSingleContextMenu'
  ];

  // Common services referencable by index
  public readonly services = {
    confirmDialog: this.injector.get<ConfirmDialogService>(ConfirmDialogService),
    externalQueryConfiguration: this.injector.get<ExternalQueryConfigurationService>(ExternalQueryConfigurationService),
    halResource: this.injector.get<HalResourceService>(HalResourceService),
    hooks: this.injector.get<HookService>(HookService),
    i18n: this.injector.get<I18nService>(I18nService),
    notifications: this.injector.get<NotificationsService>(NotificationsService),
    opModalService: this.injector.get<OpModalService>(OpModalService),
    helpTextDm: this.injector.get<HelpTextDmService>(HelpTextDmService),
    attributeHelpTexts: this.injector.get<AttributeHelpTextsService>(AttributeHelpTextsService)
  };

  // Random collection of classes needed outside of angular
  public readonly classes = {
    modals: {
      passwordConfirmation: PasswordConfirmationModal,
      attributeHelpTexts: AttributeHelpTextModal
    }
  };

  // Hooks
  public readonly hooks:{ [hook:string]:(callback:Function) => void } = {};

  // Angular2 global injector reference
  constructor(public readonly injector:Injector) {
    this
      ._knownHookNames
      .forEach((hook:string) => {
        this.hooks[hook] = (callback:Function) => this.services.hooks.register(hook, callback);
      });
  }
}
