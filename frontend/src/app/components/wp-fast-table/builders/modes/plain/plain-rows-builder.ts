import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageTable} from '../../../wp-fast-table';
import {PrimaryRenderPass} from '../../primary-render-pass';
import {SingleRowBuilder} from '../../rows/single-row-builder';
import {RowsBuilder} from '../rows-builder';
import {PlainRenderPass} from './plain-render-pass';

export class PlainRowsBuilder extends RowsBuilder {

  // Injections
  public I18n:I18nService = this.injector.get(I18nService);

  protected rowBuilder:SingleRowBuilder;

  // The group expansion state
  constructor(public readonly injector:Injector, workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
    this.rowBuilder = new SingleRowBuilder(injector, this.workPackageTable);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  public buildRows():PrimaryRenderPass {
    return new PlainRenderPass(this.injector, this.workPackageTable, this.rowBuilder).render();
  }
}
