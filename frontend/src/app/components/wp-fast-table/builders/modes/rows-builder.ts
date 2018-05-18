import {Injector} from '@angular/core';
import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {PrimaryRenderPass} from '../primary-render-pass';

export abstract class RowsBuilder {

  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector, public workPackageTable:WorkPackageTable) {
  }

  /**
   * Build all rows of the table.
   */
  public abstract buildRows():PrimaryRenderPass;

  /**
   * Determine if this builder applies to the current view mode.
   */
  public isApplicable(table:WorkPackageTable) {
    return true;
  }
}
