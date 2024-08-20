import {
  IDynamicFieldGroupConfig,
  IOPFormlyFieldSettings,
  IOPFormlyTemplateOptions,
} from 'core-app/shared/components/dynamic-forms/typings';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { Component, OnInit } from '@angular/core';
import { JobStatusModalService } from 'core-app/features/job-status/job-status-modal.service';


@Component({
  templateUrl: './copy-project.component.html',
})
export class CopyProjectComponent extends UntilDestroyedMixin implements OnInit {
  dynamicFieldsSettingsPipe = this.fieldSettingsPipe.bind(this);

  fieldGroups:IDynamicFieldGroupConfig[];

  formUrl:string;

  hiddenFields:string[] = [
    'createdAt',
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
    private jobStatusModalService:JobStatusModalService,
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
    this.jobStatusModalService.show(response.jobId as string);
  }

  private isHiddenField(key:string|undefined):boolean {
    return !!key && this.hiddenFields.includes(key);
  }

  private fieldSettingsPipe(dynamicFieldsSettings:IOPFormlyFieldSettings[]):IOPFormlyFieldSettings[] {
    return this.sortedCopyFields(dynamicFieldsSettings)
      .map((field) => ({ ...field, hide: this.isHiddenField(field.key) }));
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
    return !!property && (property.startsWith('copy') || property === 'sendNotifications');
  }

  // Sorts the copy options by their label.
  // The order of the rest of the fields is left unchanged but all copy options are returned first.
  private sortedCopyFields(dynamicFieldsSettings:IOPFormlyFieldSettings[]):IOPFormlyFieldSettings[] {
    const sortedCopyFields = dynamicFieldsSettings
      .filter((field) => field.key && field.key.startsWith('_meta.copy'))
      .sort((fieldA, fieldB) => {
        if (!fieldA.templateOptions
          || !fieldA.templateOptions.label
          || !fieldB.templateOptions
          || !fieldB.templateOptions.label) {
          return 0;
        }

        return fieldA.templateOptions.label.localeCompare(fieldB.templateOptions.label);
      });

    const nonCopyFields = dynamicFieldsSettings
      .filter((field) => !field.key || !field.key.startsWith('_meta.copy'));

    // Now all copy fields are before the non Copy fields.
    // That way, the "Sent notifications" is after the copy fields.
    // For the rest, it does not make a difference since the _meta
    // fields are rendered in a separate group.
    return sortedCopyFields.concat(nonCopyFields);
  }
}
