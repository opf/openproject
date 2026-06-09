import { Injector } from '@angular/core';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageTable } from '../../wp-fast-table';
import { PrimaryRenderPass } from '../primary-render-pass';

export abstract class RowsBuilder {
  @LazyInject() public states:States;

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
