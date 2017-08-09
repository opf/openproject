import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';

import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';

import {WorkPackageTableRow} from './wp-table.interfaces';
import {TableHandlerRegistry} from './handlers/table-handler-registry';
import {locateRow} from './helpers/wp-table-row-helpers';
import {PlainRowsBuilder} from './builders/modes/plain/plain-rows-builder';
import {GroupedRowsBuilder} from './builders/modes/grouped/grouped-rows-builder';
import {HierarchyRowsBuilder} from './builders/modes/hierarchy/hierarchy-rows-builder';
import {RowsBuilder} from './builders/modes/rows-builder';
import {WorkPackageTimelineTableController} from '../wp-table/timeline/container/wp-timeline-container.directive';
import {PrimaryRenderPass, RenderedRow} from './builders/primary-render-pass';
import {debugLog} from '../../helpers/debug_output';
import {WorkPackageEditForm} from "../wp-edit-form/work-package-edit-form";
import {TableRowEditContext} from "../wp-edit-form/table-row-edit-context";

export class WorkPackageTableEditingContext {

  public forms:{[wpId:string]:WorkPackageEditForm} = {};

  public reset() {
    _.each(this.forms, (form) => form.destroy());
    this.forms = {};
  }

  public startEditing(workPackage:WorkPackageResourceInterface, classIdentifier:string):WorkPackageEditForm {
    const wpId = workPackage.id;
    const existing = this.forms[wpId];
    if (existing) {
      return existing;
    }

    // Get any existing edit state for this work package
    const editContext = new TableRowEditContext(wpId, classIdentifier);
    return this.forms[wpId] = WorkPackageEditForm.createInContext(editContext, workPackage, false);
  }
}

