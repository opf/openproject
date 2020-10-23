import {Observable } from 'rxjs';
import {FilterSearchableMultiselectValueComponent} from 'core-components/filters/filter-searchable-multiselect-value/filter-searchable-multiselect-value.component';
import {HalResource } from 'core-app/modules/hal/resources/hal-resource';
import {ApiV3FilterBuilder } from 'core-app/components/api/api-v3/api-v3-filter-builder';
import {map } from 'rxjs/operators';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component
} from '@angular/core';

  @Component({
    templateUrl: '../../filter-searchable-multiselect-value/filter-searchable-multiselect-value.component.html',
    selector: 'wp-filter-searchable-multiselect-value',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
  export class WorkPackageFilterSearchableMultiselectValueComponent extends FilterSearchableMultiselectValueComponent implements AfterViewInit {

    public loadAvailable(matching:string):Observable<HalResource[]> {
      let filters = new ApiV3FilterBuilder();
          filters.add('is_milestone', '=', false);
          filters.add('project', '=', [this.currentProject.id]);
          if (matching) {
            filters.add('subjectOrId', '**', [matching]);
          }

          let filteredData = this
            .apiV3Service
            .work_packages
            .filtered(filters)
            .get()
            .pipe(
              map(collection => collection.elements)
            );

          return filteredData
            .pipe(
              map(items => items
            ));
    }
  }
