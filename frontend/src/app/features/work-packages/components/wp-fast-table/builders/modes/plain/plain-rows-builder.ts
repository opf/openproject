import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { WorkPackageTable } from '../../../wp-fast-table';
import { PrimaryRenderPass } from '../../primary-render-pass';
import { SingleRowBuilder } from '../../rows/single-row-builder';
import { RowsBuilder } from '../rows-builder';
import { PlainRenderPass } from './plain-render-pass';

export class PlainRowsBuilder extends RowsBuilder {
  // Injections
  @InjectField() public I18n:I18nService;

  // The group expansion state
  constructor(public readonly injector:Injector, workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  public buildRows():PrimaryRenderPass {
    const builder = new SingleRowBuilder(this.injector, this.workPackageTable);
    return new PlainRenderPass(this.injector, this.workPackageTable, builder).render();
  }
}
