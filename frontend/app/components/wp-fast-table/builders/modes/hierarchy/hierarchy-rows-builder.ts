import {Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
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
  public states:States = this.injector.get(States);
  public wpTableColumns:WorkPackageTableColumnsService = this.injector.get(WorkPackageTableColumnsService);
  public wpTableHierarchies:WorkPackageTableHierarchiesService = this.injector.get(WorkPackageTableHierarchiesService);
  public I18n:op.I18n = this.injector.get(I18nToken);

  protected rowBuilder:SingleHierarchyRowBuilder;

  // The group expansion state
  constructor(public readonly injector:Injector, public workPackageTable:WorkPackageTable) {
    super(injector,workPackageTable);
    // injectorBridge(this);
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

// HierarchyRowsBuilder.$inject = ['wpTableColumns', 'wpTableHierarchies', 'states', 'I18n'];
