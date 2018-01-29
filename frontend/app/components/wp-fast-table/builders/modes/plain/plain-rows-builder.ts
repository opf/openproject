import {Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WorkPackageTable} from '../../../wp-fast-table';
import {PrimaryRenderPass} from '../../primary-render-pass';
import {SingleRowBuilder} from '../../rows/single-row-builder';
import {RowsBuilder} from '../rows-builder';
import {PlainRenderPass} from './plain-render-pass';

export class PlainRowsBuilder extends RowsBuilder {

  // Injections
  public I18n:op.I18n = this.injector.get(I18nToken);

  protected rowBuilder:SingleRowBuilder;

  // The group expansion state
  constructor(public readonly injector:Injector, workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
    // injectorBridge(this);

    this.rowBuilder = new SingleRowBuilder(this.workPackageTable);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  public buildRows():PrimaryRenderPass {
    return new PlainRenderPass(this.workPackageTable, this.rowBuilder).render();
  }
}

// PlainRowsBuilder.$inject = ['states', 'I18n'];
