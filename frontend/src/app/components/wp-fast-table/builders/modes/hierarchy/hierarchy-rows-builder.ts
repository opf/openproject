import { Injector } from '@angular/core';
import { States } from '../../../../states.service';
import { WorkPackageTable } from '../../../wp-fast-table';
import { RowsBuilder } from '../rows-builder';
import { HierarchyRenderPass } from './hierarchy-render-pass';
import { SingleHierarchyRowBuilder } from './single-hierarchy-row-builder';
import { WorkPackageViewHierarchiesService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import { WorkPackageViewColumnsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export class HierarchyRowsBuilder extends RowsBuilder {

  // Injections
  @InjectField() states:States;
  @InjectField() wpTableColumns:WorkPackageViewColumnsService;
  @InjectField() wpTableHierarchies:WorkPackageViewHierarchiesService;

  // The group expansion state
  constructor(public readonly injector:Injector, public workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
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
    const builder = new SingleHierarchyRowBuilder(this.injector, this.workPackageTable);
    return new HierarchyRenderPass(this.injector, this.workPackageTable, builder).render();
  }
}
