import {PlainRowsBuilder} from "../plain/plain-rows-builder";
import {WorkPackageTableColumnsService} from "../../../state/wp-table-columns.service";
import {States} from "../../../../states.service";
import {WorkPackageTableHierarchiesService} from "../../../state/wp-table-hierarchy.service";
import {WorkPackageTable} from "../../../wp-fast-table";
import {injectorBridge} from "../../../../angular/angular-injector-bridge.functions";
import {SingleHierarchyRowBuilder} from "./single-hierarchy-row-builder";
import {HierarchyRenderPass} from "./hierarchy-render-pass";
import {TimelineRowBuilder} from "../../timeline/timeline-row-builder";


export class HierarchyRowsBuilder extends PlainRowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public wpTableHierarchies:WorkPackageTableHierarchiesService;
  public I18n:op.I18n;

  // Row builders
  protected rowBuilder:SingleHierarchyRowBuilder;
  protected refreshBuilder:SingleHierarchyRowBuilder;

  // The group expansion state
  constructor(public workPackageTable: WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);
  }

  /**
   * The hierarchy builder is only applicable if the hierachy mode is active
   */
  public isApplicable(_table:WorkPackageTable) {
    return this.wpTableHierarchies.isEnabled;
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public internalBuildRows(table:WorkPackageTable):[DocumentFragment,DocumentFragment] {
    const instance = new HierarchyRenderPass(table, this.rowBuilder, this.timelinebuilder);
    return [instance.tableBody, instance.timelineBody];
  }

  protected setupRowBuilders() {
    this.rowBuilder = new SingleHierarchyRowBuilder(this.stopExisting$, this.workPackageTable);
    this.timelinebuilder = new TimelineRowBuilder(this.stopExisting$, this.workPackageTable);
    this.refreshBuilder = this.rowBuilder;
  }
}


HierarchyRowsBuilder.$inject = ['wpTableColumns', 'wpTableHierarchies', 'states', 'I18n'];
