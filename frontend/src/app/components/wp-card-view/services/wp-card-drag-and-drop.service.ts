import {Inject, Injectable, Injector} from '@angular/core';
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";
import {States} from "core-components/states.service";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {RequestSwitchmap} from "core-app/helpers/rxjs/request-switchmap";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {DragAndDropHelpers} from "core-app/modules/boards/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";

@Injectable()
export class WorkPackageCardDragAndDropService {

  private _workPackages:WorkPackageResource[];

  /** Whether the card view has an active inline created wp */
  public activeInlineCreateWp?:WorkPackageResource;

  /** A reference to the component in use, to have access to the current input variables */
  public cardView:WorkPackageCardViewComponent;


  // We remember when we want to update the query with a given order
  public queryUpdates = new RequestSwitchmap(
    (order:string[]) => {
      return this.reorderService.saveOrderInQuery(this.cardView.query, order);
    }
  );

  public readonly dragService = this.injector.get(DragAndDropService, null);

  public constructor(readonly states:States,
                     readonly injector:Injector,
                     readonly reorderService:ReorderQueryService,
                     @Inject(IWorkPackageCreateServiceToken) readonly wpCreate:WorkPackageCreateService,
                     readonly wpNotifications:WorkPackageNotificationService,
                     readonly currentProject:CurrentProjectService,
                     readonly wpInlineCreate:WorkPackageInlineCreateService) {

  }

  public init(componentRef:WorkPackageCardViewComponent) {
    this.cardView = componentRef;
  }

  public destroy() {
    if (this.dragService !== null) {
      this.dragService.remove(this.cardView.container.nativeElement);
    }
  }

  public registerDragAndDrop() {
    // The DragService may not have been provided
    // in which case we do not provide drag and drop
    if (this.dragService === null) {
      return;
    }

    this.dragService.register({
      dragContainer: this.cardView.container.nativeElement,
      scrollContainers: [this.cardView.container.nativeElement],
      moves: (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;

        return this.cardView.canDragOutOf(workPackage) && !card.dataset.isNew;
      },
      accepts: () => this.cardView.dragInto,
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
   * Get current order
   */
  private get currentOrder():string[] {
    return this.workPackages
      .filter(wp => wp && !wp.isNew)
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
    this.cardView.cdRef.detectChanges();
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
        this.cardView.cdRef.detectChanges();
      });
  }

  /**
   * Add the given work package to the query
   */
  async addWorkPackageToQuery(workPackage:WorkPackageResource, toIndex:number = -1):Promise<boolean> {
    try {
      await this.cardView.workPackageAddedHandler(workPackage);
      const newOrder = await this.reorderService.add(this.currentOrder, workPackage.id!, toIndex);
      this.updateOrder(newOrder);
      return true;
    } catch (e) {
      this.wpNotifications.handleRawError(e, workPackage);
    }

    return false;
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
}
