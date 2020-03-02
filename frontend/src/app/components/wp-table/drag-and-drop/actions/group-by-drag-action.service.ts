import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {WorkPackageViewGroupByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-group-by.service";

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {rowGroupClassName} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import {locatePredecessorBySelector} from "core-components/wp-fast-table/helpers/wp-table-row-helpers";
import {groupIdentifier} from "core-components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class GroupByDragActionService extends TableDragActionService {

  @InjectField() wpTableGroupBy:WorkPackageViewGroupByService;
  @InjectField() halEditing:HalResourceEditingService;
  @InjectField() halEvents:HalEventsService;
  @InjectField() halNotification:HalResourceNotificationService;

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

  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    const changeset = this.halEditing.changeFor(workPackage);
    const groupedValue = this.getValueForGroup(el);

    changeset.projectedResource[this.groupedAttribute!] = groupedValue;
    return this.halEditing
      .save(changeset)
      .then((saved) => this.halEvents.push(saved.resource, {eventType: 'updated'}))
      .catch(e => this.halNotification.handleRawError(e, workPackage));
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
