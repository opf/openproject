import {
  IDynamicFieldGroupConfig,
  IOPFormlyFieldSettings,
  IOPFormlyTemplateOptions,
} from 'core-app/shared/components/dynamic-forms/typings';
import { JobStatusModalComponent } from 'core-app/features/job-status/job-status-modal/job-status.modal';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { Component, OnInit } from '@angular/core';
import { StateService } from '@uirouter/core';

@Component({
  selector: 'op-copy-project',
  templateUrl: './copy-project.component.html',
})
export class CopyProjectComponent extends UntilDestroyedMixin implements OnInit {
  dynamicFieldsSettingsPipe = this.fieldSettingsPipe.bind(this);

  fieldGroups:IDynamicFieldGroupConfig[];

  formUrl:string;

  hiddenFields:string[] = [
    'identifier',
    'active',
  ];

  text = {
    advancedSettingsLabel: this.I18n.t('js.forms.advanced_settings'),
    copySettingsLabel: this.I18n.t('js.project.copy.copy_options'),
  };

  constructor(
    private apiV3Service:ApiV3Service,
    private currentProjectService:CurrentProjectService,
    private pathHelperService:PathHelperService,
    private modalService:OpModalService,
    private $state:StateService,
    private I18n:I18nService,
  ) {
    super();
  }

  ngOnInit():void {
    this.formUrl = this.apiV3Service.projects.id(this.currentProjectService.id!).copy.form.path;
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
    this.modalService.show(JobStatusModalComponent, 'global', { jobId: response.jobId });
  }

  private isHiddenField(key:string|undefined):boolean {
    return !!key && this.hiddenFields.includes(key);
  }

  private fieldSettingsPipe(dynamicFieldsSettings:IOPFormlyFieldSettings[]):IOPFormlyFieldSettings[] {
    return dynamicFieldsSettings.map((field) => ({ ...field, hide: this.isHiddenField(field.key) }));
  }

  private isPrimaryAttribute(to?:IOPFormlyTemplateOptions):boolean {
    if (!to) {
      return false;
    }

    return (to.required
      && !to.hasDefault
      && to.payloadValue == null)
      || to.property === 'name'
      || to.property === 'parent';
  }

  private isMeta(property:string|undefined):boolean {
    return !!property && (property.startsWith('copy') || property == 'sendNotifications');
  }
}
