import { Component, OnInit } from '@angular/core';
import { distinctUntilChanged, filter, pluck } from "rxjs/operators";
import { UIRouterGlobals } from "@uirouter/core";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { Observable } from "rxjs";

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.scss']
})
export class ProjectsComponent extends UntilDestroyedMixin implements OnInit {
  resourceId$:Observable<string>;
  projectsPath:string;

  constructor(
    private _uIRouterGlobals:UIRouterGlobals,
    private _pathHelperService:PathHelperService,
  ) {
    super();
  }

  ngOnInit(): void {
    this.projectsPath = this._pathHelperService.projectsPath();
    this.resourceId$ = this._uIRouterGlobals
      .params$!
      .pipe(
        this.untilDestroyed(),
        pluck('projectPath'),
        distinctUntilChanged(),
      );
  }
}
