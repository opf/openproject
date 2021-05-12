import {Component, OnInit} from '@angular/core';
import {StateService, UIRouterGlobals} from "@uirouter/core";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalSource} from "core-app/modules/hal/resources/hal-resource";
import {
  IDynamicFieldGroupConfig,
  IOPFormlyFieldSettings,
  IOPFormlyTemplateOptions,
} from "core-app/modules/common/dynamic-forms/typings";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {JobStatusModal} from "core-app/modules/job-status/job-status-modal/job-status.modal";
import {OpModalService} from "core-app/modules/modal/modal.service";

@Component({
  selector: 'op-copy-project',
  templateUrl: './copy-project.component.html'
})
export class CopyProjectComponent extends UntilDestroyedMixin implements OnInit {
  dynamicFieldsSettingsPipe = this.fieldSettingsPipe.bind(this);
  fieldGroups:IDynamicFieldGroupConfig[];

  formUrl:string;

  hiddenFields:string[] = [
    'identifier',
    'active'
  ];

  text = {
    advancedSettingsLabel: this.I18n.t("js.forms.advanced_settings"),
    copySettingsLabel: this.I18n.t("js.project.copy.copy_options"),
  }

  constructor(
    private apiV3Service:APIV3Service,
    private uIRouterGlobals:UIRouterGlobals,
    private pathHelperService:PathHelperService,
    private modalService:OpModalService,
    private $state:StateService,
    private I18n:I18nService,
  ) {
    super();
  }

  ngOnInit():void {
    this.formUrl = this.apiV3Service.projects.id(this.uIRouterGlobals.params.projectPath).copy.form.path;
    this.fieldGroups = [
      {
        name: this.text.advancedSettingsLabel,
        fieldsFilter: (field:IOPFormlyFieldSettings) => !this.isMeta(field.templateOptions?.property) && !this.isPrimaryAttribute(field.templateOptions),
      },
      {
        name: this.text.copySettingsLabel,
        fieldsFilter: (field:IOPFormlyFieldSettings) => this.isMeta(field.templateOptions?.property),
      },
    ];
  }

  onSubmitted(response:HalSource) {
    this.modalService.show(JobStatusModal, 'global', { jobId: response.jobId });
  }

  private isHiddenField(key:string|undefined):boolean {
    return !!key && this.hiddenFields.includes(key);
  }

  private fieldSettingsPipe(dynamicFieldsSettings:IOPFormlyFieldSettings[]):IOPFormlyFieldSettings[] {
    return dynamicFieldsSettings.map(field => ({...field, hide: this.isHiddenField(field.key)}))
  }

  private isPrimaryAttribute(to?:IOPFormlyTemplateOptions):boolean {
    if (!to) {
      return false;
    }

    return (to.required &&
      !to.hasDefault &&
      to.payloadValue == null) ||
      to.property === 'name' ||
      to.property === 'parent';
  }

  private isMeta(property:string|undefined):boolean {
    return !!property && (property.startsWith('copy') || property == 'sendNotifications');
  }
}
