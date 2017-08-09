import {RowsBuilder} from '../rows-builder';
import {WorkPackageTable} from '../../../wp-fast-table';
import {injectorBridge} from '../../../../angular/angular-injector-bridge.functions';
import {PrimaryRenderPass} from '../../primary-render-pass';
import {PlainRenderPass} from './plain-render-pass';
import {SingleRowBuilder} from '../../rows/single-row-builder';

export class PlainRowsBuilder extends RowsBuilder {
  // Injections
  public I18n:op.I18n;

  protected rowBuilder:SingleRowBuilder;

  // The group expansion state
  constructor(workPackageTable:WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);

    this.rowBuilder = new SingleRowBuilder(this.workPackageTable);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  public buildRows():PrimaryRenderPass {
    return new PlainRenderPass(this.workPackageTable, this.rowBuilder).render();
  }
}

PlainRowsBuilder.$inject = ['states', 'I18n'];
