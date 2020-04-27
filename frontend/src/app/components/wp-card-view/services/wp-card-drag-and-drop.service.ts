import {Injectable, Injector, Optional} from '@angular/core';
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageViewOrderService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import {States} from "core-components/states.service";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {DragAndDropHelpers} from "core-app/modules/common/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Injectable()
export class WorkPackageCardDragAndDropService {

  private _workPackages:WorkPackageResource[];

  /** Whether the card view has an active inline created wp */
  public activeInlineCreateWp?:WorkPackageResource;

  /** A reference to the component in use, to have access to the current input variables */
  public cardView:WorkPackageCardViewComponent;


  public constructor(readonly states:States,
                     readonly injector:Injector,
                     readonly reorderService:WorkPackageViewOrderService,
                     readonly wpCreate:WorkPackageCreateService,
                     readonly notificationService:WorkPackageNotificationService,
                     readonly wpCacheService:WorkPackageCacheService,
                     readonly currentProject:CurrentProjectService,
                     @Optional() readonly dragService:DragAndDropService,
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
        const workPackage = this.states.workPackages.get(wpId).value;

        return !!workPackage && this.cardView.canDragOutOf(workPackage) && !card.dataset.isNew;
      },
      accepts: () => this.cardView.dragInto,
      onMoved: async (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;
        const toIndex = DragAndDropHelpers.findIndex(card);

        const newOrder = await this.reorderService.move(this.currentOrder, wpId, toIndex);
        this.updateOrder(newOrder);

        this.cardView.onMoved.emit();
      },
      onRemoved: (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;

        const newOrder = this.reorderService.remove(this.currentOrder, wpId);
        this.updateOrder(newOrder);
      },
      onAdded: async (card:HTMLElement) => {
        const wpId:string = card.dataset.workPackageId!;
        const toIndex = DragAndDropHelpers.findIndex(card);

        const workPackage = await this.wpCacheService.require(wpId);
        const result = await this.addWorkPackageToQuery(workPackage, toIndex);

        if (card.parentElement) {
          card.parentElement.removeChild(card);
        }

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
      let existingNewWp = this._workPackages.find(o => o.isNew);

      // If there is already a card for a new WP,
      // we have to replace this one by the new activeInlineCreateWp
      if (existingNewWp) {
        let index = this._workPackages.indexOf(existingNewWp);
        this._workPackages[index] = this.activeInlineCreateWp;
      } else {
        this._workPackages = [this.activeInlineCreateWp, ...workPackages];
      }
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

    Promise
      .all(newOrder.map(id => this.wpCacheService.require(id)))
      .then((workPackages:WorkPackageResource[]) => {
        this.workPackages = workPackages;
        this.cardView.cdRef.detectChanges();
      });
  }

  /**
   * Inline create a new card
   */
  public addNewCard() {
    this.wpCreate
      .createOrContinueWorkPackage(this.currentProject.identifier)
      .then((changeset:WorkPackageChangeset) => {
        this.activeInlineCreateWp = changeset.projectedResource;
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
      this.notificationService.handleRawError(e, workPackage);
    }

    return false;
  }

  /**
   * Remove the new card
   */
  public removeReferenceWorkPackageForm() {
    if (this.activeInlineCreateWp) {
      this.removeCard(this.activeInlineCreateWp);
    }
  }

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
    const index = this.workPackages.findIndex((el) => el.id === 'new');

    if (index !== -1) {
      this.activeInlineCreateWp = undefined;

      // Add this item to the results
      const newOrder = await this.reorderService.add(this.currentOrder, wp.id!, index);
      this.updateOrder(newOrder);

      // Notify inline create service
      this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id!);
    }
  }
}
