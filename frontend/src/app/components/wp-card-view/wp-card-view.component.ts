import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  OnInit,
  Output,
  ViewChild
} from "@angular/core";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {QueryColumn} from "app/components/wp-query/query-column";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {CardHighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {StateService} from "@uirouter/core";
import {States} from "core-components/states.service";
import {WorkPackageViewOrderService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {filter, map, withLatestFrom} from 'rxjs/operators';
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {CardViewHandlerRegistry} from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import {WorkPackageCardViewService} from "core-components/wp-card-view/services/wp-card-view.service";
import {WorkPackageCardDragAndDropService} from "core-components/wp-card-view/services/wp-card-drag-and-drop.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {DeviceService} from "core-app/modules/common/browser/device.service";
import {WorkPackageViewHandlerToken} from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";

export type CardViewOrientation = 'horizontal'|'vertical';

@Component({
  selector: 'wp-card-view',
  styleUrls: ['./styles/wp-card-view.component.sass', './styles/wp-card-view-horizontal.sass', './styles/wp-card-view-vertical.sass'],
  templateUrl: './wp-card-view.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WorkPackageCardViewComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input('dragOutOfHandler') public canDragOutOf:(wp:WorkPackageResource) => boolean;
  @Input() public dragInto:boolean;
  @Input() public highlightingMode:CardHighlightingMode;
  @Input() public workPackageAddedHandler:(wp:WorkPackageResource) => Promise<unknown>;
  @Input() public showStatusButton:boolean = true;
  @Input() public showInfoButton:boolean = false;
  @Input() public orientation:CardViewOrientation = 'vertical';
  /** Whether cards are removable */
  @Input() public cardsRemovable:boolean = false;
  /** Whether a notification box shall be shown when there are no WP to display */
  @Input() public showEmptyResultsBox:boolean = false;
  /** Whether on special mobile version of the cards shall be shown */
  @Input() public shrinkOnMobile:boolean = false;

  /** Container reference */
  @ViewChild('container', { static: true }) public container:ElementRef;

  @Output() public onMoved = new EventEmitter<void>();

  public trackByHref = AngularTrackingHelpers.trackByHrefAndProperty('lockVersion');
  public query:QueryResource;
  public isResultEmpty:boolean = false;
  public columns:QueryColumn[];
  public text = {
    removeCard: this.I18n.t('js.card.remove_from_list'),
    addNewCard: this.I18n.t('js.card.add_new'),
    noResults: {
      title: this.I18n.t('js.work_packages.no_results.title'),
      description: this.I18n.t('js.work_packages.no_results.description')
    },
  };

  /** Inline create / reference properties */
  public canAdd = false;
  public canReference = false;
  public inReference = false;
  public referenceClass = this.wpInlineCreate.referenceComponentClass;
  // We need to mount a dynamic component into the view
  // but map the following output
  public referenceOutputs = {
    onCancel: () => this.setReferenceMode(false),
    onReferenced: (wp:WorkPackageResource) => this.cardDragDrop.addWorkPackageToQuery(wp, 0)
  };

  constructor(readonly querySpace:IsolatedQuerySpace,
              readonly states:States,
              readonly injector:Injector,
              readonly $state:StateService,
              readonly I18n:I18nService,
              readonly wpCreate:WorkPackageCreateService,
              readonly wpInlineCreate:WorkPackageInlineCreateService,
              readonly notificationService:WorkPackageNotificationService,
              readonly halEvents:HalEventsService,
              readonly authorisationService:AuthorisationService,
              readonly causedUpdates:CausedUpdatesService,
              readonly cdRef:ChangeDetectorRef,
              readonly pathHelper:PathHelperService,
              readonly wpTableSelection:WorkPackageViewSelectionService,
              readonly wpViewOrder:WorkPackageViewOrderService,
              readonly cardView:WorkPackageCardViewService,
              readonly cardDragDrop:WorkPackageCardDragAndDropService,
              readonly deviceService:DeviceService) {
    super();
  }

  ngOnInit() {
    this.registerCreationCallback();

    // Update permission on model updates
    this.authorisationService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.canAdd = this.wpInlineCreate.canAdd;
        this.canReference = this.wpInlineCreate.canReference;
        this.cdRef.detectChanges();
      });

    // Observe changes to the work packages in this view
    this.halEvents
      .aggregated$('WorkPackage')
      .pipe(
        map(events => events.filter(event => event.eventType === 'updated')),
        filter(events => {
          const wpIds:string[] = this.workPackages.map(el => el.id!.toString());
          return !!events.find(event => wpIds.indexOf(event.id) !== -1);
        })
      ).subscribe(() => {
      this.workPackages = this.wpViewOrder.orderedWorkPackages();
      this.cdRef.detectChanges();
    });

    this.querySpace.results
      .values$()
      .pipe(
        withLatestFrom(this.querySpace.query.values$()),
        this.untilDestroyed(),
      ).subscribe(([results, query]) => {
      this.query = query;
      this.workPackages = this.wpViewOrder.orderedWorkPackages();
      this.cardView.updateRenderedCardsValues(this.workPackages);
      this.isResultEmpty = this.workPackages.length === 0;
      this.cdRef.detectChanges();
    });
  }

  ngAfterViewInit() {
    this.cardDragDrop.init(this);

    // Register Drag & Drop only on desktop
    if (!this.deviceService.isMobile) {
      this.cardDragDrop.registerDragAndDrop();
    }

    // Register event handlers for the cards
    let registry = this.injector.get<any>(WorkPackageViewHandlerToken, CardViewHandlerRegistry);
    if (registry instanceof CardViewHandlerRegistry) {
      registry.attachTo(this);
    } else {
      new registry(this.injector).attachTo(this);
    }
    this.wpTableSelection.registerSelectAllListener(() => {
      return this.cardView.renderedCards;
    });
    this.wpTableSelection.registerDeselectAllListener();
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.cardDragDrop.destroy();
  }

  public get workPackages():WorkPackageResource[] {
    return this.cardDragDrop.workPackages;
  }

  public set workPackages(workPackages:WorkPackageResource[]) {
    this.cardDragDrop.workPackages = workPackages;
  }

  public setReferenceMode(mode:boolean) {
    this.inReference = mode;
    this.cdRef.detectChanges();
  }

  public addNewCard() {
    this.cardDragDrop.addNewCard();
  }

  public removeCard(wp:WorkPackageResource) {
    this.cardDragDrop.removeCard(wp);
  }

  async onCardSaved(wp:WorkPackageResource) {
    await this.cardDragDrop.onCardSaved(wp);
  }

  public classes() {
    let classes = 'wp-cards-container ';
    classes += '-' + this.orientation;
    classes += this.shrinkOnMobile ? ' -shrink' : '';

    return classes;
  }

  /**
   * Listen to newly created work packages to detect whether the WP is the one we created,
   * and properly reset inline create in this case
   */
  private registerCreationCallback() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(async (wp:WorkPackageResource) => {
        this.onCardSaved(wp);
      });
  }
}
