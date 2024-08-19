import { Component, OnInit } from '@angular/core';
import { StateService } from '@uirouter/core';
import { IOPFormlyFieldSettings } from 'core-app/shared/components/dynamic-forms/typings';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.scss'],
})
export class ProjectsComponent extends UntilDestroyedMixin implements OnInit {
  projectsPath:string;

  formMethod = 'patch';

  text:{ [key:string]:string };

  dynamicFieldsSettingsPipe:(dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];

  hiddenFields = ['identifier', 'active'];

  constructor(
    private _pathHelperService:PathHelperService,
    private _$state:StateService,
    private _currentProjectService:CurrentProjectService,
  ) {
    super();
  }

  ngOnInit():void {
    this.projectsPath = this._currentProjectService.apiv3Path!;
    this.dynamicFieldsSettingsPipe = (dynamicFieldsSettings) => dynamicFieldsSettings
      .reduce((formattedDynamicFieldsSettings:IOPFormlyFieldSettings[], dynamicFormField) => {
        if (this.isFieldHidden(dynamicFormField.key)) {
          dynamicFormField = {
            ...dynamicFormField,
            hide: true,
          };
        }

        return [...formattedDynamicFieldsSettings, dynamicFormField];
      }, []);
  }

  private isFieldHidden(name:string|undefined) {
    return this.hiddenFields.includes(name || '');
  }
}
