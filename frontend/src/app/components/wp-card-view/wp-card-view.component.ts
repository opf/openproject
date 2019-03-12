import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Injector,
  OnInit,
  ViewChild
} from "@angular/core";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {componentDestroyed, untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {QueryColumn} from "app/components/wp-query/query-column";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageEmbeddedTableComponent} from "core-components/wp-table/embedded/wp-embedded-table.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {
  WorkPackageTableRefreshRequest,
  WorkPackageTableRefreshService
} from "core-components/wp-table/wp-table-refresh-request.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {CardReorderQueryService} from "core-components/wp-card-view/card-reorder-query.service";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {DragAndDropHelpers} from "core-app/modules/boards/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {Subject} from "rxjs";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";


@Component({
  selector: 'wp-card-view',
  styleUrls: ['./wp-card-view.component.sass'],
  templateUrl: './wp-card-view.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: ReorderQueryService, useClass: CardReorderQueryService },
  ]
})
export class WorkPackageCardViewComponent extends WorkPackageEmbeddedTableComponent implements OnInit {
  public trackByHref = AngularTrackingHelpers.trackByHref;
  public query:QueryResource;
  public workPackages:any[];
  public columns:QueryColumn[];
  public text = {
    addNewCard:  this.I18n.t('js.card.add_new'),
    wpAddedBy: (wp:WorkPackageResource) =>
      this.I18n.t('js.label_wp_id_added_by', {id: wp.id, author: wp.author.name})
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

  @ViewChild('container') public container:ElementRef;
  /** Whether the card view has an active inline created wp */
  public activeInlineCreateWp?:WorkPackageResource;

  public onCardRemoved = new Subject<undefined>();

  constructor(readonly querySpace:IsolatedQuerySpace,
              readonly injector:Injector,
              readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              @Inject(IWorkPackageCreateServiceToken) readonly wpCreate:WorkPackageCreateService,
              readonly wpInlineCreate:WorkPackageInlineCreateService,
              readonly wpNotifications:WorkPackageNotificationService,
              readonly dragService:DragAndDropService,
              readonly reorderService:ReorderQueryService,
              readonly wpTableRefresh:WorkPackageTableRefreshService,
              readonly cdRef:ChangeDetectorRef) {

    super(injector);
  }

  ngOnInit() {
    super.ngOnInit();

    this.registerDragAndDrop();

    this.registerCreationCallback();

    // Update permission on model updates
    this.authorisationService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.canAdd = this.wpInlineCreate.canAdd;
        this.canReference = this.wpInlineCreate.canReference;
        this.cdRef.detectChanges();
      });

    this.querySpace.results
    .values$()
    .pipe(
      untilComponentDestroyed(this)
    ).subscribe((results) => {
      if (this.activeInlineCreateWp) {
        this.workPackages = [this.activeInlineCreateWp, ...results.$embedded.elements];
      } else {
        this.workPackages = results.$embedded.elements;
      }

      this.removeDragged();
      this.cdRef.detectChanges();
    });
  }

  ngOnDestroy():void {
    this.onCardRemoved.complete();
    this.dragService.remove(this.container.nativeElement);
  }

  protected filterRefreshRequest(request:WorkPackageTableRefreshRequest):boolean {
    return request.origin !== 'create';
  }

  public hasAssignee(wp:WorkPackageResource) {
    return !!wp.assignee;
  }

  public get isDraggable() {
    return this.configuration.dragAndDropEnabled;
  }

  public handleDblClick(wp:WorkPackageResource) {
    this.goToWpFullView(wp.id);
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

  public typeDotClass(wp:WorkPackageResource) {
    return Highlighting.dotClass('type',  wp.type.getId());
  }

  removeDragged() {
    this.container.nativeElement
      .querySelectorAll('.__was_dragged')
      .forEach((el:HTMLElement) => {
        el.parentElement && el.parentElement!.removeChild(el);
      });
  }

  registerDragAndDrop() {
    if (!this.configuration.dragAndDropEnabled) {
      return;
    }

    this.dragService.register({
      container: this.container.nativeElement,
      moves: (card:HTMLElement) => !card.dataset.isNew,
      onMoved: (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;
        const toIndex = DragAndDropHelpers.findIndex(card);

        this.reorderService
          .move(this.querySpace, wpId, toIndex)
          .then(() => this.wpTableRefresh.request('Drag and Drop moved item'));
      },
      onRemoved: (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;

        this.reorderService
          .remove(this.querySpace, wpId)
          .then(() => this.wpTableRefresh.request('Drag and Drop removed item'));
      },
      onAdded: async (card:HTMLElement) => {
        // Fix to ensure items that are virtually added get removed quickly
        card.classList.add('__was_dragged');
        const wpId:string = card.dataset.workPackageId!;
        const toIndex = DragAndDropHelpers.findIndex(card);

        const workPackage = this.states.workPackages.get(wpId).value!;
        return await this.addWorkPackageToQuery(workPackage, toIndex);
      }
    });
  }

  /**
   * Add the given work package to the query
   */
  async addWorkPackageToQuery(workPackage:WorkPackageResource, toIndex:number = -1):Promise<boolean> {
    try {
      await this.reorderService.updateWorkPackage(this.querySpace, workPackage);
      await this.reorderService.add(this.querySpace, workPackage.id, toIndex);
      this.wpTableRefresh.request('Drag and Drop added item');
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
        const wp = changeset.workPackage;
        this.activeInlineCreateWp = wp;
        this.workPackages = [wp, ...this.workPackages];
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
  removeNewCard() {
    const wp = this.activeInlineCreateWp;

    if (!wp) {
      return;
    }

    const index = this.workPackages.indexOf(wp);
    this.workPackages.splice(index, 1);
    this.activeInlineCreateWp = undefined;
    this.onCardRemoved.next();
    this.cdRef.detectChanges();
  }

  /**
   * On new card saved
   */
  async onCardSaved(wp:WorkPackageResource) {
    if (this.activeInlineCreateWp && this.activeInlineCreateWp.__initialized_at === wp.__initialized_at) {
      const index = this.workPackages.indexOf(this.activeInlineCreateWp);
      this.activeInlineCreateWp = undefined;

      // Add this item to the results
      await this.reorderService.add(this.querySpace, wp.id, index);

      // Notify inline create service
      this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id);

      this.refresh();
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
