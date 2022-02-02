import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import {
  DynamicComponentDefinition,
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
  ViewPartitionState,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { WorkPackageFilterButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { WorkPackageFilterContainerComponent } from 'core-app/features/work-packages/components/filters/filter-container/filter-container.directive';
import { QueryParamListenerService } from 'core-app/features/work-packages/components/wp-query/query-param-listener.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageSettingsButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-settings-button/wp-settings-button.component';
import { CalendarDragDropService } from 'core-app/features/team-planner/team-planner/calendar-drag-drop.service';

@Component({
  templateUrl: '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    QueryParamListenerService,
    CalendarDragDropService,
  ],
})
export class TeamPlannerPageComponent extends PartitionedQuerySpacePageComponent implements OnInit {
  text = {
    title: this.I18n.t('js.team_planner.title'),
    unsaved_title: this.I18n.t('js.team_planner.unsaved_title'),
  };

  /** Go back using back-button */
  backButtonCallback:() => void;

  /** Current query title to render */
  selectedTitle = this.text.unsaved_title;

  filterContainerDefinition:DynamicComponentDefinition = {
    component: WorkPackageFilterContainerComponent,
  };

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  /** Show a toolbar */
  showToolbar = true;

  /** Toolbar is not editable */
  titleEditingEnabled = false;

  /** Savable */
  showToolbarSaveButton = true;

  /** Toolbar is always enabled */
  toolbarDisabled = false;

  /** Define the buttons shown in the toolbar */
  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageFilterButtonComponent,
    },
    {
      component: ZenModeButtonComponent,
    },
    {
      component: WorkPackageSettingsButtonComponent,
      containerClasses: 'hidden-for-mobile',
      show: ():boolean => this.authorisationService.can('query', 'updateImmediately'),
      inputs: {
        hideTableOptions: true,
      },
    },
  ];

  public ngOnInit():void {
    super.ngOnInit();

    this.wpTableFilters.hidden.push(
      'assignee',
      'startDate',
      'dueDate',
      'memberOfGroup',
      'assignedToRole',
      'assigneeOrGroup',
    );
  }

  /**
   * We need to set the current partition to the grid to ensure
   * either side gets expanded to full width if we're not in '-split' mode.
   *
   * @param state The current or entering state
   */
  setPartition(state:{ data:{ partition?:ViewPartitionState } }):void {
    this.currentPartition = state.data?.partition || '-split';
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  protected staticQueryName(query:QueryResource):string {
    return this.text.unsaved_title;
  }

  /**
   * @protected
   */
  protected loadInitialQuery():void {
    // We never load the initial query as the calendar service does all that.
  }
}
