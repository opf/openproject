import {Injector} from '@angular/core';
import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {PrimaryRenderPass} from '../primary-render-pass';
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export abstract class RowsBuilder {

  @InjectField() public states:States;

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
