import {States} from '../../states.service';
import {WorkPackageTable} from '../wp-fast-table';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {$injectFields} from '../../angular/angular-injector-bridge.functions';
import {TimelineRenderPass} from './timeline/timeline-render-pass';
import {SingleRowBuilder} from './rows/single-row-builder';
import {RelationRenderInfo, RelationsRenderPass} from './relations/relations-render-pass';
import {timeOutput} from '../../../helpers/debug_output';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';

export type RenderedRowType = 'primary' | 'relations';

export interface RowRenderInfo {
  // Unique class name as an identifier to uniquely identify the row in both table and timeline
  classIdentifier:string;
  // Additional classes to be added by any secondary render passes
  additionalClasses:string[];
  // If this row is a work package, contains a reference to the rendered WP
  workPackage:WorkPackageResourceInterface|null;
  // If this is an additional row not present, this contains a reference to the WP
  // it originated from
  belongsTo?:WorkPackageResourceInterface;
  // The type of row this was rendered from
  renderType:RenderedRowType;
  // Marks if the row is currently hidden to the user
  hidden:boolean;
  // Additional data by the render passes
  data?:any;
}

export type RenderedRow = { classIdentifier:string, workPackageId:string|null, hidden:boolean };

export abstract class PrimaryRenderPass {
  public wpEditing:WorkPackageEditingService;
  public states:States;
  public I18n:op.I18n;

  /** The rendered order of rows of work package IDs or <null>, if not a work package row */
  public renderedOrder:RowRenderInfo[];

  /** Resulting table body */
  public tableBody:DocumentFragment;

  /** Additional render pass that handles timeline rendering */
  public timeline:TimelineRenderPass;

  /** Additional render pass that handles table relation rendering */
  public relations:RelationsRenderPass;

  constructor(public workPackageTable:WorkPackageTable,
              public rowBuilder:SingleRowBuilder) {
    $injectFields(this, 'states', 'I18n', 'wpEditing');

  }

  /**
   * Execute the entire render pass, executing this pass and all subsequent registered passes
   * for timeline and relations.
   * @return {PrimaryRenderPass}
   */
  public render():this {

    timeOutput('Primary render pass', () => {

      // Prepare and reset the render pass
      this.prepare();

      // Render into the table fragment
      this.doRender();
    });

    // Render subsequent passes
    // that may modify the structure of the table
    timeOutput('Relations render pass', () => {
      this.relations.render();
    });

    // Synchronize the rows to timeline
    timeOutput('Timelines render pass', () => {
      this.timeline.render();
    });

    return this;
  }

  /**
   * Refresh a single row using the render pass it was originally created from.
   * @param row
   */
  public refresh(row:RowRenderInfo, workPackage:WorkPackageResourceInterface, body:HTMLElement) {
    let oldRow = jQuery(body).find(`.${row.classIdentifier}`);
    let replacement:JQuery|null = null;
    let editing = this.wpEditing.changesetFor(workPackage);

    switch(row.renderType) {
      case 'primary':
        replacement =  this.rowBuilder.refreshRow(workPackage, editing, oldRow);
        break;
      case 'relations':
        replacement = this.relations.refreshRelationRow(row as RelationRenderInfo, workPackage, editing, oldRow);
    }

    if (replacement !== null && oldRow.length) {
      oldRow.replaceWith(replacement);
    }
  }

  public get result():RenderedRow[] {
    return this.renderedOrder.map((row) => {
      return {
        classIdentifier: row.classIdentifier,
        workPackageId: row.workPackage ? row.workPackage.id : null,
        hidden: row.hidden
      } as RenderedRow;
    });
  }

  /**
   * Splice a row into a specific location of the current render pass through the given selector.
   *
   * 1. Insert into the document fragment after the last match of the selector
   * 2. Splice into the renderedOrder array.
   */
  public spliceRow(row:HTMLElement, selector:string, renderedInfo:RowRenderInfo) {
    // Insert into table using the selector
    // If it matches multiple, select the last element
    const target = jQuery(this.tableBody)
      .find(selector)
      .last();

    target.after(row);

    // Splice the renderedOrder at this exact location
    const index = target.index();
    this.renderedOrder.splice(index + 1, 0, renderedInfo);
  }


  protected prepare() {
    this.timeline = new TimelineRenderPass(this.workPackageTable, this);
    this.relations = new RelationsRenderPass(this.workPackageTable, this);
    this.tableBody = document.createDocumentFragment();
    this.renderedOrder = [];
  }

  /**
   * The actual render function of this renderer.
   */
  protected abstract doRender():void;

  /**
   * Append a work package row to both containers
   * @param workPackage The work package, if the row belongs to one
   * @param row HTMLElement to append
   * @param rowClasses Additional classes to apply to the timeline row for mirroring purposes
   * @param hidden whether the row was rendered hidden
   */
  protected appendRow(workPackage:WorkPackageResourceInterface,
                      row:HTMLElement,
                      additionalClasses:string[] = [],
                      hidden:boolean = false) {

    this.tableBody.appendChild(row);

    this.renderedOrder.push({
      classIdentifier: this.rowBuilder.classIdentifier(workPackage),
      additionalClasses: additionalClasses,
      workPackage: workPackage,
      renderType: 'primary',
      hidden: hidden
    });
  }

  /**
   * Append a non-work package row to both containers
   * @param row HTMLElement to append
   * @param classIdentifer a unique identifier for the two rows (one each in table/timeline).
   * @param hidden whether the row was rendered hidden
   */
  protected appendNonWorkPackageRow(row:HTMLElement,
                                    classIdentifer:string,
                                    additionalClasses:string[] = [],
                                    hidden:boolean = false) {
    row.classList.add(classIdentifer);
    this.tableBody.appendChild(row);

    this.renderedOrder.push({
      classIdentifier: classIdentifer,
      additionalClasses: additionalClasses,
      workPackage: null,
      renderType: 'primary',
      hidden: hidden
    });
  }
}
