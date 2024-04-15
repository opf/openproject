import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { MAGIC_PAGE_NUMBER } from 'core-app/core/apiv3/helpers/get-paginated-results';

@Component({
  templateUrl: './subprojects.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetSubprojectsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    noResults: this.i18n.t('js.grid.widgets.subprojects.no_results'),
  };

  public projects:ProjectResource[];

  constructor(
    readonly halResource:HalResourceService,
    readonly pathHelper:PathHelperService,
    readonly i18n:I18nService,
    protected readonly injector:Injector,
    readonly timezone:TimezoneService,
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
    readonly cdr:ChangeDetectorRef,
  ) {
    super(i18n, injector);
  }

  ngOnInit() {
    this
      .apiV3Service
      .projects
      .list(this.projectListParams)
      .subscribe((collection) => {
        this.projects = collection.elements;

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

  private get projectListParams():ApiV3ListParameters {
    return {
      sortBy: [['name', 'asc']],
      filters: [['parent_id', '=', [this.currentProject.id!]], ['active', '=', ['t']]],
      pageSize: MAGIC_PAGE_NUMBER,
    };
  }
}
