import {WorkPackageTableMetadata} from '../wp-table-metadata';
import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {State} from '../../../helpers/reactive-fassade';
import {WPTableRowSelectionState} from '../wp-table.interfaces';

export class WorkPackageTableMetadataService {

  // The current table metadata state
  public metadata:State<WorkPackageTableMetadata>;

  constructor(public states: States) {
    "ngInject";
    this.metadata = states.table.metadata;
  }

  /**
   * Returns whether the given column is contained in the current set
   * of groupable columns.
   */
  public isGroupable(name:string):boolean {
    return !!_.find(this.current.groupableColumns, (column) => column.name === name);
  }

  public showSums():boolean {
    return !!this.current.totalSums;
  }

  /**
   * Get current selection state.
   * @returns {WPTableRowSelectionState}
   */
  public get current():WorkPackageTableMetadata {
    return this.metadata.getCurrentValue();
  }
}

opServicesModule.service('wpTableMetadata', WorkPackageTableMetadataService);








