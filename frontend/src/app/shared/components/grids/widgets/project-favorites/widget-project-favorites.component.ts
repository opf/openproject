import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  HostBinding,
  Injector,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { Observable } from 'rxjs';

@Component({
  templateUrl: './widget-project-favorites.component.html',
  styleUrls: ['./widget-project-favorites.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetProjectFavoritesComponent extends AbstractWidgetComponent implements OnInit {
  @HostBinding('class.op-widget-project-favorites') className = true;

  public text = {
    no_favorites: this.i18n.t('js.favorite_projects.no_results'),
    no_favorites_subtext: this.i18n.t('js.favorite_projects.no_results_subtext'),
  };

  public projects$:Observable<ProjectResource[]>;

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
    const filters = new ApiV3FilterBuilder();
    filters.add('favored', '=', true);
    filters.add('active', '=', true);

    this.projects$ = this
      .apiV3Service
      .projects
      .filtered(filters, { pageSize: '-1' })
      .getPaginatedResults();
  }

  projectPath(project:ProjectResource) {
    return this.pathHelper.projectPath(project.identifier);
  }
}
