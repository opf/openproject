import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {rowGroupClassName} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import {locatePredecessorBySelector} from "core-components/wp-fast-table/helpers/wp-table-row-helpers";
import {groupIdentifier} from "core-components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';

export class GroupByDragActionService extends TableDragActionService {

  private wpTableGroupBy = this.injector.get(WorkPackageTableGroupByService);
  private wpEditing = this.injector.get<WorkPackageEditingService>(IWorkPackageEditingServiceToken);
  private wpNotifications = this.injector.get(WorkPackageNotificationService);
  private wpTableRefresh = this.injector.get(WorkPackageTableRefreshService);

  public get applies() {
    return this.wpTableGroupBy.isEnabled;
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    const attribute = this.groupedAttribute;
    return attribute !== null && workPackage.isAttributeEditable(attribute);
  }

  /**
   * We need to refresh the table results to get the correct group count.
   * @param _newOrder
   */
  public onNewOrder(_newOrder:string[]):void {
    this.wpTableRefresh.request('Dropped in group mode');
  }

  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    const changeset = this.wpEditing.changesetFor(workPackage);
    const groupedValue = this.getValueForGroup(el);

    changeset.setValue(this.groupedAttribute!, groupedValue);
    return changeset
      .save()
      .catch(e => this.wpNotifications.handleRawError(e, workPackage));
  }

  private getValueForGroup(el:HTMLElement):unknown|null {
    const groupHeader = locatePredecessorBySelector(el, `.${rowGroupClassName}`)!;
    const match = this.groups.find(group => groupIdentifier(group) === groupHeader.dataset.groupIdentifier);

    if (!match) {
      return null;
    }

    if (match._links && match._links.valueLink) {
      const links = match._links.valueLink;

      // Unwrap single links to properly use them
      return links.length === 1 ? links[0] : links;
    } else {
      return match.value;
    }
  }

  /**
   * Get the attribute we're grouping by
   */
  private get groupedAttribute():string|null {
    const current = this.wpTableGroupBy.current;
    return current ? current.id : null;
  }

  /**
   * Returns the reference to the last table.groups state value
   */
  public get groups() {
    return this.querySpace.groups.value || [];
  }
}
