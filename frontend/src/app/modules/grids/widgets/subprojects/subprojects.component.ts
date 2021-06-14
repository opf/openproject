import { AbstractWidgetComponent } from "core-app/modules/grids/widgets/abstract-widget.component";
import { Component, OnInit, ChangeDetectorRef, Injector, ChangeDetectionStrategy } from '@angular/core';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HalResourceService } from "core-app/modules/hal/services/hal-resource.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { Apiv3ListParameters } from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";

@Component({
  templateUrl: './subprojects.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetSubprojectsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    noResults: this.i18n.t('js.grid.widgets.subprojects.no_results'),
  };

  public projects:ProjectResource[];

  constructor(readonly halResource:HalResourceService,
              readonly pathHelper:PathHelperService,
              readonly i18n:I18nService,
              protected readonly injector:Injector,
              readonly timezone:TimezoneService,
              readonly apiV3Service:APIV3Service,
              readonly currentProject:CurrentProjectService,
              readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this
      .apiV3Service
      .projects
      .list(this.projectListParams)
      .subscribe((collection) => {
        this.projects = collection.elements as ProjectResource[];

        this.cdr.detectChanges();
      });
  }

  public get isEditable() {
    return false;
  }

  public projectPath(project:ProjectResource) {
    return this.pathHelper.projectPath(project.identifier);
  }

  public projectName(project:ProjectResource) {
    return project.name;
  }

  public get noEntries() {
    return this.projects && !this.projects.length;
  }

  private get projectListParams():Apiv3ListParameters {
    return { sortBy: [['name', 'asc']],
      filters: [['parent_id', '=', [this.currentProject.id!]]] };
  }
}
