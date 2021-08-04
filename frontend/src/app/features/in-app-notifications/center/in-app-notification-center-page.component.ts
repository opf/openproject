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
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationSettingsButtonComponent } from 'core-app/features/in-app-notifications/center/toolbar/settings/notification-settings-button.component';
import { ActivateFacetButtonComponent } from 'core-app/features/in-app-notifications/center/toolbar/facet/activate-facet-button.component';
import { MarkAllAsReadButtonComponent } from 'core-app/features/in-app-notifications/center/toolbar/mark-all-as-read/mark-all-as-read-button.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  templateUrl: '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterPageComponent extends UntilDestroyedMixin {
  text = {
    title: this.I18n.t('js.notifications.title'),
  };

  /** Go back using back-button */
  // TODO: Use better Function which actually leaves the notification page and don't only toggle the split views
  backButtonCallback = ():void => window.history.back();

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

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: ActivateFacetButtonComponent,
      containerClasses: 'form--field-inline-buttons-container',
    },
    {
      component: MarkAllAsReadButtonComponent,
    },
    {
      component: NotificationSettingsButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
  ];

  constructor(
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transitions:TransitionService,
    readonly state:StateService,
    readonly notifications:NotificationsService,
    readonly injector:Injector,
    readonly apiV3Service:APIV3Service,
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

  // For Interface compliance
  updateTitleName(val:string) {}

  // For Interface compliance
  changeChangesFromTitle(val:string) {}
}
