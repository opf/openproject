import {$injectFields, injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {States} from "../../../states.service";
import {collapsedGroupClass, hierarchyGroupClass, hierarchyRootClass} from "../../helpers/wp-table-hierarchy-helpers";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableHierarchiesService} from './../../state/wp-table-hierarchy.service';
import {WorkPackageTableHierarchies} from "../../wp-table-hierarchies";
import {indicatorCollapsedClass} from "../../builders/modes/hierarchy/single-hierarchy-row-builder";
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {debugLog} from '../../../../helpers/debug_output';
import {WorkPackageTableRelationColumnsService} from '../../state/wp-table-relation-columns.service';
import {WorkPackageTableRelationColumns} from '../../wp-table-relation-columns';

export class RelationsTransformer {
  public wpTableRelationColumns:WorkPackageTableRelationColumnsService;
  public states:States;

  constructor(table:WorkPackageTable) {
    $injectFields(this, 'wpTableRelationColumns', 'states');

    this.states.updates.relationUpdates
      .values$('Refreshing expanded relations on user request')
      .subscribe((state: WorkPackageTableRelationColumns) => {
        table.redrawTableAndTimeline();
      });
  }
}
