import {ApplicationRef, Injector, NgZone} from "@angular/core";
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
import {DynamicContentModal} from "../../components/modals/modal-wrapper/dynamic-content.modal";
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {EditFieldService} from "core-app/modules/fields/edit/edit-field.service";
import {OpenProjectFileUploadService} from "core-components/api/op-file-upload/op-file-upload.service";
import {EditorMacrosService} from "core-components/modals/editor/editor-macros.service";
import {HTMLSanitizeService} from "../common/html-sanitize/html-sanitize.service";
import {PathHelperService} from "../common/path-helper/path-helper.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {States} from 'core-components/states.service';
import {CKEditorPreviewService} from "core-app/modules/common/ckeditor/ckeditor-preview.service";
import {ExternalRelationQueryConfigurationService} from "core-components/wp-table/external-configuration/external-relation-query-configuration.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

/**
 * Plugin context bridge for plugins outside the CLI compiler context
 * in order to access services and parts of the core application
 */
export class OpenProjectPluginContext {

  private _knownHookNames = [
    'workPackageTableContextMenu',
    'workPackageSingleContextMenu',
    'workPackageNewInitialization'
  ];

  // Common services referencable by index
  public readonly services = {
    confirmDialog: this.injector.get<ConfirmDialogService>(ConfirmDialogService),
    externalQueryConfiguration: this.injector.get<ExternalQueryConfigurationService>(ExternalQueryConfigurationService),
    externalRelationQueryConfiguration: this.injector.get<ExternalRelationQueryConfigurationService>(ExternalRelationQueryConfigurationService),
    halResource: this.injector.get<HalResourceService>(HalResourceService),
    hooks: this.injector.get<HookService>(HookService),
    i18n: this.injector.get<I18nService>(I18nService),
    notifications: this.injector.get<NotificationsService>(NotificationsService),
    opModalService: this.injector.get<OpModalService>(OpModalService),
    opFileUpload: this.injector.get<OpenProjectFileUploadService>(OpenProjectFileUploadService),
    helpTextDm: this.injector.get<HelpTextDmService>(HelpTextDmService),
    attributeHelpTexts: this.injector.get<AttributeHelpTextsService>(AttributeHelpTextsService),
    displayField: this.injector.get<DisplayFieldService>(DisplayFieldService),
    editField: this.injector.get<EditFieldService>(EditFieldService),
    wpCache: this.injector.get<WorkPackageCacheService>(WorkPackageCacheService),
    macros: this.injector.get<EditorMacrosService>(EditorMacrosService),
    htmlSanitizeService: this.injector.get<HTMLSanitizeService>(HTMLSanitizeService),
    ckEditorPreview: this.injector.get<CKEditorPreviewService>(CKEditorPreviewService),
    pathHelperService: this.injector.get<PathHelperService>(PathHelperService),
    states: this.injector.get<States>(States),
  };

  // Random collection of classes needed outside of angular
  public readonly classes = {
    modals: {
      passwordConfirmation: PasswordConfirmationModal,
      attributeHelpTexts: AttributeHelpTextModal,
      dynamicContent: DynamicContentModal,
    },
    HalResource: HalResource,
    DisplayField: DisplayField
  };

  // Hooks
  public readonly hooks:{ [hook:string]:(callback:Function) => void } = {};

  // Angular zone reference
  @InjectField() public readonly zone:NgZone;

  // Angular2 global injector reference
  constructor(public readonly injector:Injector) {
    this
      ._knownHookNames
      .forEach((hook:string) => {
        this.hooks[hook] = (callback:Function) => this.services.hooks.register(hook, callback);
      });
  }

  /**
   * Run the given callback in the angular zone,
   * resulting in triggered change detection that would otherwise not occur.
   *
   * @param cb
   */
  public runInZone(cb:() => void) {
    this.zone.run(cb);
  }

  /**
   * Bootstrap a dynamically embeddable component
   * @param element
   */
  public bootstrap(element:HTMLElement) {
    DynamicBootstrapper.bootstrapOptionalEmbeddable(
      this.injector.get(ApplicationRef),
      element
    );
  }
}
