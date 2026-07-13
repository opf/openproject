import { ApplicationRef, Injector } from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ExternalQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { EditFieldService } from 'core-app/shared/components/fields/edit/edit-field.service';
import { States } from 'core-app/core/states/states.service';
import { CKEditorPreviewService } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-preview.service';
import {
  ExternalRelationQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-relation-query-configuration.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { EditorMacrosService } from 'core-app/shared/components/modals/editor/editor-macros.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { PathHelperService } from '../../core/path-helper/path-helper.service';
import { HTMLSanitizeService } from '../../core/html-sanitize/html-sanitize.service';
import { DynamicContentModalComponent } from '../../shared/components/modals/modal-wrapper/dynamic-content.modal';
import { DomAutoscrollService } from 'core-app/shared/helpers/drag-and-drop/dom-autoscroll.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { HttpClient } from '@angular/common/http';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { HalEventsService } from '../hal/services/hal-events.service';
/**
 * Plugin context bridge for plugins outside the CLI compiler context
 * in order to access services and parts of the core application
 */
export class OpenProjectPluginContext {
  private _knownHookNames = [
    'workPackageBulkContextMenu',
    'workPackageTableContextMenu',
    'workPackageSingleContextMenu',
    'workPackageNewInitialization',
  ];

  // Common services referenceable by index
  public readonly services = {
    confirmDialog: this.injector.get<ConfirmDialogService>(ConfirmDialogService),
    externalQueryConfiguration: this.injector.get<ExternalQueryConfigurationService>(ExternalQueryConfigurationService),
    externalRelationQueryConfiguration: this.injector.get<ExternalRelationQueryConfigurationService>(ExternalRelationQueryConfigurationService),
    halEvents: this.injector.get<HalEventsService>(HalEventsService),
    halResource: this.injector.get<HalResourceService>(HalResourceService),
    hooks: this.injector.get<HookService>(HookService),
    i18n: this.injector.get<I18nService>(I18nService),
    notifications: this.injector.get<ToastService>(ToastService),
    timezone: this.injector.get<TimezoneService>(TimezoneService),
    opModalService: this.injector.get<OpModalService>(OpModalService),
    displayField: this.injector.get<DisplayFieldService>(DisplayFieldService),
    editField: this.injector.get<EditFieldService>(EditFieldService),
    macros: this.injector.get<EditorMacrosService>(EditorMacrosService),
    htmlSanitizeService: this.injector.get<HTMLSanitizeService>(HTMLSanitizeService),
    ckEditorPreview: this.injector.get<CKEditorPreviewService>(CKEditorPreviewService),
    pathHelperService: this.injector.get<PathHelperService>(PathHelperService),
    states: this.injector.get<States>(States),
    apiV3Service: this.injector.get<ApiV3Service>(ApiV3Service),
    configurationService: this.injector.get<ConfigurationService>(ConfigurationService),
    attachmentsResourceService: this.injector.get(AttachmentsResourceService),
    http: this.injector.get(HttpClient),
    turboRequests: this.injector.get(TurboRequestsService),
    currentProject: this.injector.get(CurrentProjectService),
  };

  public readonly helpers = {
    idFromLink,
  };

  // Random collection of classes needed outside of angular
  public readonly classes = {
    modals: {
      dynamicContent: DynamicContentModalComponent,
    },
    HalResource,
    DisplayField,
    DomAutoscrollService,
  };

  // Hooks
  /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
  public readonly hooks:Record<string, (callback:(...args:any[]) => unknown) => void> = {};

  /**
   * @deprecated Noop shim — the app is zoneless. Remove usages.
   */
  public readonly zone = {
    run: <T>(cb:() => T):T => cb(),
    runOutsideAngular: <T>(cb:() => T):T => cb(),
  };

  // Angular application reference
  @LazyInject() public readonly appRef:ApplicationRef;

  // Angular2 global injector reference
  constructor(public readonly injector:Injector) {
    this
      ._knownHookNames
      .forEach((hook:string) => {
        this.hooks[hook] = (callback:() => void) => this.services.hooks.register(hook, callback);
      });
  }

  /**
   * @deprecated This method is a no-op since the app is zoneless.
   * Replace calls with direct invocation of the callback.
   */
  public runInZone(cb:() => void) {
    cb();
  }
}
