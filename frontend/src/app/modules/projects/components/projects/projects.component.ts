import { Component, OnInit } from '@angular/core';
import { StateService, UIRouterGlobals } from "@uirouter/core";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { IOPFormlyFieldSettings } from "core-app/modules/common/dynamic-forms/typings";

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.scss']
})
export class ProjectsComponent extends UntilDestroyedMixin implements OnInit {
  resourceId:string;
  projectsPath:string;
  text:{[key:string]:string};
  dynamicFieldsSettingsPipe:(dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];

  constructor(
    private _uIRouterGlobals:UIRouterGlobals,
    private _pathHelperService:PathHelperService,
    private _$state:StateService,
  ) {
    super();
  }

  ngOnInit(): void {
    this.projectsPath = this._pathHelperService.projectsPath();
    this.resourceId = this._uIRouterGlobals.params.projectPath;
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
}
