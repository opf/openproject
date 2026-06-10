import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { WidgetTimeEntriesListComponent } from 'core-app/shared/components/grids/widgets/time-entries/list/time-entries-list.component';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';

@Component({
  templateUrl: '../list/time-entries-list.component.html',
  providers: [
    HalResourceEditingService,
  ],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WidgetTimeEntriesProjectComponent extends WidgetTimeEntriesListComponent implements OnInit {
  protected readonly currentProject = inject(CurrentProjectService);

  protected dmFilters():[string, FilterOperator, [string]][] {
    return [['spentOn', '>t-', ['7']] as [string, FilterOperator, [string]],
      ['project_id', '=', [this.currentProject.id]] as [string, FilterOperator, [string]]];
  }
}
