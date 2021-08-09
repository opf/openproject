import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
  OnInit,
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
import {
  BackRouteOptions,
  BackRoutingService,
} from 'core-app/features/work-packages/components/back-routing/back-routing.service';

@Component({
  templateUrl: '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterPageComponent extends UntilDestroyedMixin implements OnInit {
  text = {
    title: this.I18n.t('js.notifications.title'),
  };

  /** Go back using back-button */
  backButtonCallback:() => void = this.backButtonFn.bind(this);

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

  /** Global referrer set when coming from a hard reload */
  private documentReferer:string;

  /** Local referrer set when coming from an angular route */
  private backRoute:BackRouteOptions;

  constructor(
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transitions:TransitionService,
    readonly state:StateService,
    readonly notifications:NotificationsService,
    readonly injector:Injector,
    readonly apiV3Service:APIV3Service,
    readonly backRoutingService:BackRoutingService,
  ) {
    super();
  }

  ngOnInit():void {
    this.backRoute = this.backRoutingService.backRoute;
    this.documentReferer = document.referrer;
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
  updateTitleName(val:string):void {} // eslint-disable-line class-methods-use-this, no-unused-vars

  // For shared template compliance
  changeChangesFromTitle(val:string):void {} // eslint-disable-line class-methods-use-this, no-unused-vars

  private backButtonFn():void {
    if (this.backRoute) {
      void this.backRoutingService.goToOtherState(this.backRoute.name, this.backRoute.params);
      return;
    }

    if (this.documentReferer.length > 0) {
      window.location.href = this.documentReferer;
    } else {
      // Default fallback
      window.history.back();
    }
  }
}
