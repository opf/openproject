import {States} from '../../states.service';
import {WorkPackageTable} from '../wp-fast-table';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {$injectFields} from '../../angular/angular-injector-bridge.functions';
import {rowClass} from '../helpers/wp-table-row-helpers';
import {TimelineRenderPass} from './timeline/timeline-render-pass';
import {SingleRowBuilder} from './rows/single-row-builder';
import {RelationsRenderPass} from './relations/relations-render-pass';

export interface RenderedRow {
  isWorkPackage:boolean;
  belongsTo?:WorkPackageResourceInterface;
  hidden:boolean;
}

export interface TableRenderResult {
  renderedOrder:RenderedRow[];
}

export interface SecondaryRenderPass {
  render():void;
}

export abstract class PrimaryRenderPass {
  public states:States;
  public I18n:op.I18n;

  /** The rendered order of rows of work package IDs or <null>, if not a work package row */
  public renderedOrder:RenderedRow[];

  /** Resulting table body */
  public tableBody:DocumentFragment;

  /** Additional render pass that handles timeline rendering */
  public timeline:TimelineRenderPass;

  /** Additional render pass that handles table relation rendering */
  public relations:SecondaryRenderPass;

  constructor(public workPackageTable:WorkPackageTable, public rowBuilder:SingleRowBuilder) {
    $injectFields(this, 'states', 'I18n');

  }

  public render():this {
    // Prepare and reset the render pass
    this.prepare();

    // Render into the table fragment
    this.doRender();

    // Render subsequent passes
    // that may modify the structure of the table
    this.relations.render();

    // Synchronize the rows to timeline
    this.timeline.render();

    return this;
  }

  /**
   * Augment a new row added by a secondary render pass with whatever information is needed
   * by the current render mode.
   *
   * e.g., add a class name to demark which group this element belongs to.
   *
   * @param row The HTMLElement to be inserted by the secondary render pass.
   * @param belongsTo The RenderedRow the element will be inserted for.
   * @return {HTMLElement} The augmented row element.
   */
  public augmentSecondaryElement(row:HTMLElement, belongsTo:RenderedRow):HTMLElement {
    return row;
  }

  public get result():TableRenderResult {
    return {
      renderedOrder: this.renderedOrder
    };
  }

  /**
   * Splice a row into a specific location of the current render pass through the given selector.
   *
   * 1. Insert into the document fragment after the last match of the selector
   * 2. Splice into the renderedOrder array.
   */
  public spliceRow(row:HTMLElement, selector:string, renderedInfo:RenderedRow) {
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
                      hidden:boolean = false) {

    this.tableBody.appendChild(row);

    this.renderedOrder.push({
      isWorkPackage: true,
      belongsTo: workPackage,
      hidden: hidden
    });
  }

  /**
   * Append a non-work package row to both containers
   * @param row HTMLElement to append
   * @param classIdentifer a unique identifier for the two rows (one each in table/timeline).
   * @param hidden whether the row was rendered hidden
   */
  protected appendNonWorkPackageRow(row:HTMLElement, classIdentifer:string, hidden:boolean = false) {
    row.classList.add(classIdentifer);
    this.tableBody.appendChild(row);

    this.renderedOrder.push({
      isWorkPackage: false,
      hidden: hidden
    });
  }
}
