import { Component, OnInit } from '@angular/core';
import { StateService, UIRouterGlobals } from "@uirouter/core";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.scss'],
})
export class ProjectsComponent extends UntilDestroyedMixin implements OnInit {
  resourceId:string|null;
  projectsPath:string;
  text:{ [key:string]:string };

  constructor(
    private uIRouterGlobals:UIRouterGlobals,
    private pathHelperService:PathHelperService,
  ) {
    super();
  }

  ngOnInit():void {
    this.projectsPath = this.pathHelperService.projectsPath();
    this.resourceId = this.uIRouterGlobals.params.projectPath;
  }

  onSubmitted(formResource:HalSource) {
    if (!this.resourceId && typeof formResource.identifier === 'string') {
      window.location.href = this.pathHelperService.projectPath(formResource.identifier);
    }
  }
}
