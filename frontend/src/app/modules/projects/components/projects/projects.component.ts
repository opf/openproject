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
    this._uIRouterGlobals
      .params$!
      .pipe(
        this.untilDestroyed(),
        pluck('projectPath'),
        distinctUntilChanged(),
      )
      .subscribe(resourceId => this.resourceId = resourceId);
  }

  onSubmitted(formResource:HalSource) {
    if (!this.resourceId) {
      this._$state.go('.', { ...this._$state.params, projectPath: formResource.identifier });
    }
  }
}
