import {ChangeDetectionStrategy, Component, OnInit} from "@angular/core";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {ProjectCacheService} from "core-components/projects/project-cache.service";

@Component({
  templateUrl: './project-single-widget.component.html',
  selector: 'project-single-widget',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ProjectSingleWidgetComponent implements OnInit {

  public project:any;

  constructor(private readonly currentProject:CurrentProjectService,
              private projectCache:ProjectCacheService) {

  }

  ngOnInit() {
    this.projectCache.require(this.currentProject.id!).then((p) => {
      this.project = p;
    });
  }
}