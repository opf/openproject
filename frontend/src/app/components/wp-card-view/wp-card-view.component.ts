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
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {QueryColumn} from "app/components/wp-query/query-column";
import {combine} from "reactivestates/dist";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageEmbeddedTableComponent} from "core-components/wp-table/embedded/wp-embedded-table.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {OpTableActionsService} from "core-components/wp-table/table-actions/table-actions.service";
import {WorkPackageTableTimelineService} from "core-components/wp-fast-table/state/wp-table-timeline.service";
import {WorkPackageTablePaginationService} from "core-components/wp-fast-table/state/wp-table-pagination.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageTableRelationColumnsService} from "core-components/wp-fast-table/state/wp-table-relation-columns.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {WorkPackageTableColumnsService} from "core-components/wp-fast-table/state/wp-table-columns.service";
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableSelection} from "core-components/wp-fast-table/state/wp-table-selection.service";
import {WorkPackageTableSumService} from "core-components/wp-fast-table/state/wp-table-sum.service";
import {WorkPackageTableAdditionalElementsService} from "core-components/wp-fast-table/state/wp-table-additional-elements.service";
import {
  WorkPackageTableRefreshRequest,
  WorkPackageTableRefreshService
} from "core-components/wp-table/wp-table-refresh-request.service";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {CardReorderQueryService} from "core-components/wp-card-view/card-reorder-query.service";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";
import {DragAndDropHelpers} from "core-app/modules/boards/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";


@Component({
  selector: 'wp-card-view',
  styleUrls: ['./wp-card-view.component.sass'],
  templateUrl: './wp-card-view.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    IsolatedQuerySpace,
    OpTableActionsService,
    WorkPackageInlineCreateService,
    WorkPackageTableRelationColumnsService,
    WorkPackageTablePaginationService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableTimelineService,
    WorkPackageTableSelection,
    WorkPackageTableSumService,
    WorkPackageTableAdditionalElementsService,
    WorkPackageTableRefreshService,
    WorkPackageTableHighlightingService,
    { provide: IWorkPackageCreateServiceToken, useClass: WorkPackageCreateService },
    // Order is important here, to avoid this service
    // getting global injections
    WorkPackageStatesInitializationService,
    { provide: ReorderQueryService, useClass: CardReorderQueryService },
  ]
})
export class WorkPackageCardViewComponent extends WorkPackageEmbeddedTableComponent implements OnInit {
  public trackByHref = AngularTrackingHelpers.trackByHref;
  public query:QueryResource;
  public workPackages:any[];
  public columns:QueryColumn[];
  public availableColumns:QueryColumn[];
  public text = {
    addNewCard: 'Add new card',
    wpAddedBy: (wp:WorkPackageResource) =>
      this.I18n.t('js.label_wp_id_added_by', {id: wp.id, author: wp.author.name})
  };

  @ViewChild('container') public container:ElementRef;

  /** Whether the card view has an active inline created wp */
  public activeInlineCreateWp?:WorkPackageResource;

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

    combine(
      this.querySpace.columns,
      this.querySpace.results
    )
    .values$()
    .pipe(
      untilComponentDestroyed(this)
    )
    .subscribe(([columns, results]) => {

      if (this.activeInlineCreateWp) {
        this.workPackages = [...results.$embedded.elements, this.activeInlineCreateWp];
      } else {
        this.workPackages = results.$embedded.elements;
      }

      this.removeDragged();

      this.columns = columns;
      this.availableColumns = this.columns.filter(function (column) {
        return column.id !== 'id' && column.id !== 'subject' && column.id !== 'author';
      });

      this.cdRef.detectChanges();
    });
  }

  ngOnDestroy():void {
    this.dragService.remove(this.container.nativeElement);
  }

  protected filterRefreshRequest(request:WorkPackageTableRefreshRequest):boolean {
    return request.origin !== 'create';
  }

  public hasAssignee(wp:WorkPackageResource) {
    return !!wp.assignee;
  }

  public get canAdd() {
    return this.wpInlineCreate.canAdd;
  }

  public get isDraggable() {
    return this.configuration.dragAndDropEnabled;
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

        try {
          await this.reorderService.updateWorkPackage(this.querySpace, workPackage);
          await this.reorderService.add(this.querySpace, wpId, toIndex);
          this.wpTableRefresh.request('Drag and Drop added item');
          return true;
        } catch (e) {
          this.wpNotifications.handleRawError(e, workPackage);
        }

        return false;
      }
    });
  }


  /**
   * Inline create a new card
   */
  addNewCard() {
    this.wpCreate
      .createOrContinueWorkPackage(this.currentProject.identifier)
      .then((changeset:WorkPackageChangeset) => {
        this.activeInlineCreateWp = changeset.workPackage;
        this.workPackages = [...this.workPackages, this.activeInlineCreateWp];
        this.cdRef.detectChanges();
      });
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
        if (this.activeInlineCreateWp && this.activeInlineCreateWp.__initialized_at === wp.__initialized_at) {
          const index = this.workPackages.indexOf(this.activeInlineCreateWp);
          this.activeInlineCreateWp = undefined;

          // Add this item to the results
          await this.reorderService.add(this.querySpace, wp.id, index);

          // Notify inline create service
          this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id);

          this.refresh();
        }
      });
  }

  /**
   * Remove the new card
   */
  removeNewCard(wp:WorkPackageResource) {
    const index = this.workPackages.indexOf(wp);
    this.workPackages.splice(index, 1);
    this.activeInlineCreateWp = undefined;
    this.cdRef.detectChanges();
  }
}
