import { Component, OnInit } from '@angular/core';
import { StateService, UIRouterGlobals } from "@uirouter/core";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { IOPFormlyFieldSettings } from "core-app/modules/common/dynamic-forms/typings";

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.scss']
})
export class ProjectsComponent extends UntilDestroyedMixin implements OnInit {
  resourceId:string;
  projectsPath:string;
  text:{ [key:string]:string };
  dynamicFieldsSettingsPipe:(dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];
  hiddenFields = ['identifier', 'active'];

  constructor(
    private _uIRouterGlobals:UIRouterGlobals,
    private _pathHelperService:PathHelperService,
    private _$state:StateService,
  ) {
    super();
  }

  ngOnInit():void {
    this.projectsPath = this._pathHelperService.projectsPath();
    this.resourceId = this._uIRouterGlobals.params.projectPath;
    this.dynamicFieldsSettingsPipe = (dynamicFieldsSettings) => {
      return dynamicFieldsSettings
        .reduce((formattedDynamicFieldsSettings, dynamicFormField) => {
          if (this.isFieldHidden(dynamicFormField.key)) {
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
    // TODO: Filter out if this.resourceId === 'new'?
    if (!this.resourceId) {
      this._$state.go('.', { ...this._$state.params, projectPath: formResource.identifier });
    }
  }

  private isFieldHidden(name:string|undefined) {
    return this.hiddenFields.includes(name || '');
  }
}
