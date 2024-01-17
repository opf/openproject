import { Injectable } from '@angular/core';
import { StateService } from '@uirouter/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Observable } from 'rxjs';
import { IView } from 'core-app/core/state/views/view.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Injectable()
export class WorkPackagesQueryViewService {
  // Todo: Delete the whole attribute with feature flag `show_separate_gantt_module`
  private query:QueryResource;

  constructor(
    protected $state:StateService,
    protected apiV3Service:ApiV3Service,
    // Todo: Delete the whole attribute with feature flag `show_separate_gantt_module`
    protected configurationService:ConfigurationService,
  ) { }

  create(query:QueryResource):Observable<IView> {
    if (!query.href) {
      throw new Error('Expected only queries that are created since an href is required');
    }

    // Todo: Delete the whole attribute with feature flag `show_separate_gantt_module`
    this.query = query;

    return this
      .apiV3Service
      .views
      .post(
        {
          _links: {
            query: {
              href: query.href,
            },
          },
        },
        this.viewType,
      );
  }

  private get viewType() {
    // Todo: Delete the whole attribute with feature flag `show_separate_gantt_module`
    if (!this.configurationService.activeFeatureFlags.includes('showSeparateGanttModule')) {
      // Queries with an activated Gantt should already get the ViewType "gantt"
      if (this.$state.includes('work-packages') && this.query.timelineVisible) {
        return 'gantt';
      }
    }

    if (this.$state.includes('work-packages')) {
      return 'work_packages_table';
    }
    if (this.$state.includes('team_planner')) {
      return 'team_planner';
    }
    if (this.$state.includes('bim')) {
      return 'bim';
    }
    if (this.$state.includes('calendar')) {
      return 'work_packages_calendar';
    }
    if (this.$state.includes('gantt')) {
      return 'gantt';
    }

    throw new Error('Not on a path defined for query views');
  }
}
