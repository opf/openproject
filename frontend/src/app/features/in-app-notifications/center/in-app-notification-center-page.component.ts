import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
  OnDestroy,
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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationSettingsButtonComponent } from 'core-app/features/in-app-notifications/center/toolbar/settings/notification-settings-button.component';
import { ActivateFacetButtonComponent } from 'core-app/features/in-app-notifications/center/toolbar/facet/activate-facet-button.component';
import { MarkAllAsReadButtonComponent } from 'core-app/features/in-app-notifications/center/toolbar/mark-all-as-read/mark-all-as-read-button.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { BackRoutingService } from 'core-app/features/work-packages/components/back-routing/back-routing.service';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';

@Component({
  templateUrl: '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  providers: [
    IanCenterService,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterPageComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
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

  /** Listener callbacks */
  // eslint-disable-next-line @typescript-eslint/ban-types
  removeTransitionSubscription:Function;

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

  /** Global referrer set when coming to the notification center */
  private documentReferer:string;

  constructor(
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transitions:TransitionService,
    readonly state:StateService,
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
    readonly backRoutingService:BackRoutingService,
    readonly titleService:OpTitleService,
  ) {
    super();
  }

  ngOnInit():void {
    this.documentReferer = document.referrer;
    this.titleService.prependFirstPart(this.text.title);

    this.removeTransitionSubscription = this.$transitions.onSuccess({}, ():any => {
      this.titleService.setFirstPart(this.text.title);
    });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.removeTransitionSubscription();
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

  private backButtonFn():void {
    if (this.documentReferer.length > 0) {
      window.location.href = this.documentReferer;
    } else {
      // Default fallback
      window.history.back();
    }
  }
}
