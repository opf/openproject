import { Component, OnInit } from '@angular/core';
import { StateService, UIRouterGlobals } from "@uirouter/core";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { HalResource, HalSource } from "core-app/modules/hal/resources/hal-resource";
import { IOPFormlyFieldSettings } from "core-app/modules/common/dynamic-forms/typings";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { FormControl, FormGroup } from "@angular/forms";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { map } from "rxjs/operators";
import { Observable } from "rxjs";
import { JobStatusModal } from "core-app/modules/job-status/job-status-modal/job-status.modal";
import { OpModalService } from "core-app/modules/modal/modal.service";

export interface ProjectTemplateOption {
  href:string|null;
  title:string;
}

@Component({
  selector: 'op-new-project',
  templateUrl: './new-project.component.html',
})
export class NewProjectComponent extends UntilDestroyedMixin implements OnInit {
  resourcePath:string;
  dynamicFieldsSettingsPipe:(dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];

  text = {
    use_template: this.I18n.t('js.project.use_template'),
  };

  copyableTemplateFilter = new ApiV3FilterBuilder()
    .add('user_action', '=', ["projects/copy"]) // no null values
    .add('templated', '=', true);

  templateOptions$:Observable<ProjectTemplateOption[]> =
    this
      .apiV3Service
      .projects
      .filtered(this.copyableTemplateFilter)
      .get()
      .pipe(
        map(response =>
          response.elements.map((el:HalResource) => ({ href: el.href, name: el.name }))),
      );

  templateForm = new FormGroup({
    template: new FormControl(),
  });

  get templateControl() {
    return this.templateForm.get('template');
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
    this.resourcePath = this.pathHelperService.projectsPath();

    this.dynamicFieldsSettingsPipe = (dynamicFieldsSettings) => {
      const fieldsLayoutConfig = dynamicFieldsSettings
        .reduce((result, field) => {
        if (
          (field.templateOptions?.required &&
          !field.templateOptions.hasDefault &&
          field.templateOptions.payloadValue == null) ||
          field.templateOptions?.property === 'name' ||
          field.templateOptions?.property === 'parent'
        ) {
          result.firstLevelFields = [...result.firstLevelFields, field];
        } else {
          result.advancedSettingsFields = [...result.advancedSettingsFields, field];
        }

        return result;
      }, {firstLevelFields: [], advancedSettingsFields: []} as {firstLevelFields: IOPFormlyFieldSettings[], advancedSettingsFields: IOPFormlyFieldSettings[]});
      const advancedSettingsGroup = {
        fieldGroup: fieldsLayoutConfig.advancedSettingsFields,
        fieldGroupClassName: "op-form--field-group",
        templateOptions: {
          label: this.I18n.t("js.forms.advanced_settings"),
          collapsibleFieldGroups: true,
          collapsibleFieldGroupsCollapsed: true,
        },
        type: "formly-group" as "formly-group",
        wrappers: ["op-dynamic-field-group-wrapper"],
      }

      return [...fieldsLayoutConfig.firstLevelFields, advancedSettingsGroup];
    }
  }

  onSubmitted(response:HalSource) {
    if (response._type === 'JobStatus') {
      this.modalService.show(JobStatusModal, 'global', { jobId: response.jobId });
    } else {
      this.$state.go('.', { projectPath: response.identifier });
    }
  }

  onTemplateSelected(selected:{ href:string|null }) {
    if (selected.href) {
      // TODO avoid resourcePath handling by passing form endpoint
      this.resourcePath = selected.href.replace('/api/v3', '') + '/copy';
    } else {
      this.resourcePath = this.pathHelperService.projectsPath();
    }
  }
}
