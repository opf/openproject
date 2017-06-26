import {WorkPackageTableColumnsService} from '../../../state/wp-table-columns.service';
import {States} from '../../../../states.service';
import {WorkPackageTableHierarchiesService} from '../../../state/wp-table-hierarchy.service';
import {WorkPackageTable} from '../../../wp-fast-table';
import {injectorBridge} from '../../../../angular/angular-injector-bridge.functions';
import {SingleHierarchyRowBuilder} from './single-hierarchy-row-builder';
import {HierarchyRenderPass} from './hierarchy-render-pass';
import {RowsBuilder} from '../rows-builder';

export class HierarchyRowsBuilder extends RowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public wpTableHierarchies:WorkPackageTableHierarchiesService;
  public I18n:op.I18n;

  protected rowBuilder:SingleHierarchyRowBuilder;

  // The group expansion state
  constructor(public workPackageTable:WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);
    this.rowBuilder = new SingleHierarchyRowBuilder(this.workPackageTable);
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
    return new HierarchyRenderPass(this.workPackageTable, this.rowBuilder).render();
  }
}

HierarchyRowsBuilder.$inject = ['wpTableColumns', 'wpTableHierarchies', 'states', 'I18n'];
