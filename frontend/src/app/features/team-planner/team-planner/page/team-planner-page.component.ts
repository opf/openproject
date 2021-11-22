import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
} from '@angular/core';
import {
  ToolbarButtonComponentDefinition,
  ViewPartitionState,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import {
  StateService,
  TransitionService,
} from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { BackRoutingService } from 'core-app/features/work-packages/components/back-routing/back-routing.service';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';

@Component({
  templateUrl: '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TeamPlannerPageComponent extends UntilDestroyedMixin {
  text = {
    title: this.I18n.t('js.team_planner.title'),
  };

  /** Go back using back-button */
  backButtonCallback:() => void;

  /** Current query title to render */
  selectedTitle = this.text.title;

  /** Disable filter container for now */
  filterContainerDefinition = null;

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  /** Show a toolbar */
  showToolbar = true;

  /** Toolbar is not editable */
  titleEditingEnabled = false;

  /** Not savable */
  showToolbarSaveButton = false;

  /** Toolbar is always enabled */
  toolbarDisabled = false;

  /** Define the buttons shown in the toolbar */
  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: ZenModeButtonComponent,
    },
  ];

  constructor(
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transitions:TransitionService,
    readonly state:StateService,
    readonly injector:Injector,
    readonly apiV3Service:APIV3Service,
    readonly backRoutingService:BackRoutingService,
  ) {
    super();
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

  // For shared template compliance
  // eslint-disable-next-line class-methods-use-this, @typescript-eslint/no-unused-vars
  updateTitleName(val:string):void {
  }

  // For shared template compliance
  // eslint-disable-next-line class-methods-use-this, @typescript-eslint/no-unused-vars
  changeChangesFromTitle(val:string):void {
  }
}
