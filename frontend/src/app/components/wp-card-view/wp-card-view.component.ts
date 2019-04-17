import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Injector,
  Input,
  OnInit,
  ViewChild
} from "@angular/core";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {componentDestroyed, untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {QueryColumn} from "app/components/wp-query/query-column";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {DragAndDropHelpers} from "core-app/modules/boards/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";
import {CardHighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {StateService} from "@uirouter/core";
import {States} from "core-components/states.service";
import {input} from "reactivestates";
import {switchMap, tap} from "rxjs/operators";
import {RequestSwitchmap} from "core-app/helpers/rxjs/request-switchmap";


@Component({
  selector: 'wp-card-view',
  styleUrls: ['./wp-card-view.component.sass'],
  templateUrl: './wp-card-view.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WorkPackageCardViewComponent  implements OnInit {
  @Input() public dragAndDropEnabled:boolean;
  @Input() public highlightingMode:CardHighlightingMode;
  @Input() public workPackageAddedHandler:(wp:WorkPackageResource) => Promise<unknown>;
  @Input() public showStatusButton:boolean = true;

  public trackByHref = AngularTrackingHelpers.trackByHref;
  public query:QueryResource;
  private _workPackages:WorkPackageResource[];
  public columns:QueryColumn[];
  public text = {
    removeCard: this.I18n.t('js.card.remove_from_list'),
    addNewCard:  this.I18n.t('js.card.add_new'),
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
    onReferenced: (wp:WorkPackageResource) => this.addWorkPackageToQuery(wp, 0)
  };

  /** Whether cards are removable */
  @Input() public cardsRemovable:boolean = false;

  /** Container reference */
  @ViewChild('container') public container:ElementRef;

  /** Whether the card view has an active inline created wp */
  public activeInlineCreateWp?:WorkPackageResource;

  // We remember when we want to update the query with a given order
  private queryUpdates = new RequestSwitchmap(
    (order:string[]) => this.reorderService.saveOrderInQuery(this.query, order)
  );

  constructor(readonly querySpace:IsolatedQuerySpace,
              readonly states:States,
              readonly injector:Injector,
              readonly $state:StateService,
              readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              @Inject(IWorkPackageCreateServiceToken) readonly wpCreate:WorkPackageCreateService,
              readonly wpInlineCreate:WorkPackageInlineCreateService,
              readonly wpNotifications:WorkPackageNotificationService,
              readonly dragService:DragAndDropService,
              readonly reorderService:ReorderQueryService,
              readonly authorisationService:AuthorisationService,
              readonly cdRef:ChangeDetectorRef) {
  }

  ngOnInit() {
    this.registerDragAndDrop();

    this.registerCreationCallback();

    // Keep query loading requests
    this.queryUpdates
      .observe(componentDestroyed(this))
      .subscribe({
        error: (error:any) => this.wpNotifications.handleRawError(error)
      });

    // Update permission on model updates
    this.authorisationService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.canAdd = this.wpInlineCreate.canAdd;
        this.canReference = this.wpInlineCreate.canReference;
        this.cdRef.detectChanges();
      });

    this.querySpace.query
    .values$()
    .pipe(
      untilComponentDestroyed(this)
    ).subscribe((query:QueryResource) => {
      this.query = query;
      this.workPackages = query.results.elements;
      this.cdRef.detectChanges();
    });
  }

  ngOnDestroy():void {
    this.dragService.remove(this.container.nativeElement);
  }

  public hasAssignee(wp:WorkPackageResource) {
    return !!wp.assignee;
  }

  public handleDblClick(wp:WorkPackageResource) {
    this.goToWpFullView(wp.id!);
  }

  private goToWpFullView(wpId:string) {
    this.$state.go(
      'work-packages.show',
      {workPackageId: wpId}
    );
  }

  public wpTypeAttribute(wp:WorkPackageResource) {
    return wp.type.name + ':';
  }

  public wpSubject(wp:WorkPackageResource) {
    return wp.subject;
  }

  public cardHighlightingClass(wp:WorkPackageResource) {
    return this.cardHighlighting(wp);
  }

  public typeHighlightingClass(wp:WorkPackageResource) {
    return this.attributeDotHighlighting('type', wp);
  }

  private cardHighlighting(wp:WorkPackageResource) {
    if (['status', 'priority', 'type'].includes(this.highlightingMode)) {
      return Highlighting.rowClass(this.highlightingMode, wp[this.highlightingMode].id);
    }
    return '';
  }

  private attributeDotHighlighting(type:string, wp:WorkPackageResource) {
    if (this.highlightingMode === 'inline') {
      return Highlighting.dotClass(type, wp.type.id!);
    }
    return '';
  }

  registerDragAndDrop() {
    this.dragService.register({
      dragContainer: this.container.nativeElement,
      scrollContainers: [this.container.nativeElement],
      moves: (card:HTMLElement) => this.dragAndDropEnabled && !card.dataset.isNew,
      onMoved: (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;
        const toIndex = DragAndDropHelpers.findIndex(card);

        const newOrder = this.reorderService.move(this.currentOrder, wpId, toIndex);
        this.updateOrder(newOrder);
      },
      onRemoved: (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;

        const newOrder = this.reorderService.remove(this.currentOrder, wpId);
        this.updateOrder(newOrder);
      },
      onAdded: async (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;
        const toIndex = DragAndDropHelpers.findIndex(card);

        const workPackage = this.states.workPackages.get(wpId).value!;
        const result = await this.addWorkPackageToQuery(workPackage, toIndex);

        card.parentElement!.removeChild(card);

        return result;
      }
    });
  }

  /**
   * Get current order
   */
  private get currentOrder():string[] {
    return this.workPackages
      .filter(wp => !wp.isNew)
      .map(el => el.id!);
  }

  /**
   * Update current order
   */
  private updateOrder(newOrder:string[]) {
    newOrder = _.uniq(newOrder);

    this.workPackages = newOrder.map(id => this.states.workPackages.get(id).value!);
    // Ensure dragged work packages are being removed.
    this.queryUpdates.request(newOrder);
    this.cdRef.detectChanges();
  }

  /**
   * Get the current work packages
   */
  public get workPackages():WorkPackageResource[] {
    return this._workPackages;
  }

  /**
   * Set work packages array,
   * remembering to keep the active inline-create
   */
  public set workPackages(workPackages:WorkPackageResource[]) {
    if (this.activeInlineCreateWp) {
      this._workPackages = [this.activeInlineCreateWp, ...workPackages];
    } else {
      this._workPackages = [...workPackages];
    }
  }


  /**
   * Add the given work package to the query
   */
  async addWorkPackageToQuery(workPackage:WorkPackageResource, toIndex:number = -1):Promise<boolean> {
    try {
      await this.workPackageAddedHandler(workPackage);
      const newOrder = await this.reorderService.add(this.currentOrder, workPackage.id!, toIndex);
      this.updateOrder(newOrder);
      return true;
    } catch (e) {
      this.wpNotifications.handleRawError(e, workPackage);
    }

    return false;
  }


  /**
   * Inline create a new card
   */
  public addNewCard() {
    this.wpCreate
      .createOrContinueWorkPackage(this.currentProject.identifier)
      .then((changeset:WorkPackageChangeset) => {
        this.activeInlineCreateWp = changeset.workPackage;
        this.workPackages = this.workPackages;
        this.cdRef.detectChanges();
      });
  }

  public setReferenceMode(mode:boolean) {
    this.inReference = mode;
    this.cdRef.detectChanges();
  }

  /**
   * Remove the new card
   */
  removeCard(wp:WorkPackageResource) {
    const index = this.workPackages.indexOf(wp);
    this.workPackages.splice(index, 1);
    this.activeInlineCreateWp = undefined;

    if (!wp.isNew) {
      const newOrder = this.reorderService.remove(this.currentOrder, wp.id!);
      this.updateOrder(newOrder);
    }
  }

  /**
   * On new card saved
   */
  async onCardSaved(wp:WorkPackageResource) {
    if (this.activeInlineCreateWp && this.activeInlineCreateWp.__initialized_at === wp.__initialized_at) {
      const index = this.workPackages.indexOf(this.activeInlineCreateWp);
      this.activeInlineCreateWp = undefined;

      // Add this item to the results
      const newOrder = await this.reorderService.add(this.currentOrder, wp.id!, index);
      this.updateOrder(newOrder);

      // Notify inline create service
      this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id!);
    }
  }


  /**
   * Listen to newly created work packages to detect whether the WP is the one we created,
   * and properly reset inline create in this case
   */
  private registerCreationCallback() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(untilComponentDestroyed(this))
      .subscribe(async (wp:WorkPackageResource) => {
        this.onCardSaved(wp);
      });
  }
}
