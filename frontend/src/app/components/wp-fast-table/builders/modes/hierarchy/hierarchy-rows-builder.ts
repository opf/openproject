import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {States} from '../../../../states.service';
import {WorkPackageTableColumnsService} from '../../../state/wp-table-columns.service';
import {WorkPackageTableHierarchiesService} from '../../../state/wp-table-hierarchy.service';
import {WorkPackageTable} from '../../../wp-fast-table';
import {RowsBuilder} from '../rows-builder';
import {HierarchyRenderPass} from './hierarchy-render-pass';
import {SingleHierarchyRowBuilder} from './single-hierarchy-row-builder';

export class HierarchyRowsBuilder extends RowsBuilder {

  // Injections
  public states = this.injector.get(States);
  public wpTableColumns = this.injector.get(WorkPackageTableColumnsService);
  public wpTableHierarchies = this.injector.get(WorkPackageTableHierarchiesService);

  protected rowBuilder:SingleHierarchyRowBuilder;

  // The group expansion state
  constructor(public readonly injector:Injector, public workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
    this.rowBuilder = new SingleHierarchyRowBuilder(injector, this.workPackageTable);
  }

  /**
   * The hierarchy builder is only applicable if the hierachy mode is active
   */
  public isApplicable(_table:WorkPackageTable) {
    return this.wpTableHierarchies.isEnabled;
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  public buildRows():HierarchyRenderPass {
    return new HierarchyRenderPass(this.injector, this.workPackageTable, this.rowBuilder).render();
  }
}
