import { Component, OnInit } from '@angular/core';
import { StateService, UIRouterGlobals } from "@uirouter/core";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { IOPFormlyFieldSettings } from "core-app/modules/common/dynamic-forms/typings";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { FormControl, FormGroup } from "@angular/forms";
import { of } from "rxjs";

@Component({
  selector: 'app-projects',
  templateUrl: './new-project.component.html'
})
export class NewProjectComponent extends UntilDestroyedMixin implements OnInit {
  resourcePath:string;
  dynamicFieldsSettingsPipe:(dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];

  text = {
    use_template: this.I18n.t('js.project.use_template')
  }

  // TODO
  templateOptions$ = of([
    { href: null, title: '(none)' },
    { href: '/api/v3/projects/12', title: 'First project' },
    { href: '/api/v3/projects/13', title: 'Second project' },
  ]);

  templateForm = new FormGroup({
    template: new FormControl()
  });

  get templateControl() { return this.templateForm.get('template'); }

  constructor(
    private uIRouterGlobals:UIRouterGlobals,
    private pathHelperService:PathHelperService,
    private $state:StateService,
    private I18n:I18nService,
  ) {
    super();
  }

  ngOnInit(): void {
    this.resourcePath = this.pathHelperService.projectsPath();

    // TODO extract common
    this.dynamicFieldsSettingsPipe = (dynamicFieldsSettings) => {
      return dynamicFieldsSettings
        .reduce((formattedDynamicFieldsSettings, dynamicFormField) => {
          if (dynamicFormField.key === 'identifier') {
            dynamicFormField = {
              ...dynamicFormField,
              hide: true,
            }
          }

          return [...formattedDynamicFieldsSettings, dynamicFormField];
        }, []);
    }
  }

  onSubmitted(formResource:HalSource) {
    this.$state.go('.', { projectPath: formResource.identifier });
  }

  onTemplateSelected(selected:{ href:string|null }) {
    if (selected.href) {
      this.resourcePath = selected.href.replace('/api/v3', '') + '/copy';
    } else {
      this.resourcePath = this.pathHelperService.projectsPath();
    }
  }
}
