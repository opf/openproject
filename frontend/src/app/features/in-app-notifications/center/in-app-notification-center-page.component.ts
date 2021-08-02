import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
} from '@angular/core';
import { ViewPartitionState } from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import {
  StateService,
  TransitionService,
} from '@uirouter/core';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { InAppNotificationToolbarComponent } from 'core-app/features/in-app-notifications/center/toolbar/in-app-notification-toolbar.component';

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

  /** Go back to boards using back-button */
  backButtonCallback = ():void => window.history.back();

  /** Current query title to render */
  selectedTitle = this.text.title;

  /** Disable filter container for now */
  filterContainerDefinition = null;

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  toolbarComponent = InAppNotificationToolbarComponent;

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
}
