import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {timeOutput} from '../../../helpers/debug_output';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from '../../states.service';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {WorkPackageTable} from '../wp-fast-table';
import {RelationRenderInfo, RelationsRenderPass} from './relations/relations-render-pass';
import {SingleRowBuilder} from './rows/single-row-builder';
import {TimelineRenderPass} from './timeline/timeline-render-pass';
import {
  IWorkPackageEditingServiceToken
} from "../../wp-edit-form/work-package-editing.service.interface";
import {HighlightingRenderPass} from "core-components/wp-fast-table/builders/highlighting/row-highlight-render-pass";

export type RenderedRowType = 'primary' | 'relations';

export interface RowRenderInfo {
  // Unique class name as an identifier to uniquely identify the row in both table and timeline
  classIdentifier:string;
  // Additional classes to be added by any secondary render passes
  additionalClasses:string[];
  // If this row is a work package, contains a reference to the rendered WP
  workPackage:WorkPackageResource | null;
  // If this is an additional row not present, this contains a reference to the WP
  // it originated from
  belongsTo?:WorkPackageResource;
  // The type of row this was rendered from
  renderType:RenderedRowType;
  // Marks if the row is currently hidden to the user
  hidden:boolean;
  // Additional data by the render passes
  data?:any;
}

export type RenderedRow = { classIdentifier:string, workPackageId:string | null, hidden:boolean };

export abstract class PrimaryRenderPass {

  public wpEditing:WorkPackageEditingService = this.injector.get<WorkPackageEditingService>(IWorkPackageEditingServiceToken);
  public states:States = this.injector.get(States);
  public I18n:I18nService = this.injector.get(I18nService);

  /** The rendered order of rows of work package IDs or <null>, if not a work package row */
  public renderedOrder:RowRenderInfo[];

  /** Resulting table body */
  public tableBody:DocumentFragment;

  /** Additional render pass that handles timeline rendering */
  public timeline:TimelineRenderPass;

  /** Additional render pass that handles table relation rendering */
  public relations:RelationsRenderPass;

  /** Additional render pass that handles highlighting of rows */
  public highlighting:HighlightingRenderPass;

  constructor(public readonly injector:Injector,
              public workPackageTable:WorkPackageTable,
              public rowBuilder:SingleRowBuilder) {
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
    this.highlighting.render();

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
  public refresh(row:RowRenderInfo, workPackage:WorkPackageResource, body:HTMLElement) {
    let oldRow = jQuery(body).find(`.${row.classIdentifier}`);
    let replacement:JQuery | null = null;

    switch (row.renderType) {
      case 'primary':
        replacement = this.rowBuilder.refreshRow(workPackage, oldRow);
        break;
      case 'relations':
        replacement = this.relations.refreshRelationRow(row as RelationRenderInfo, workPackage, oldRow);
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
    this.timeline = new TimelineRenderPass(this.injector, this.workPackageTable, this);
    this.relations = new RelationsRenderPass(this.injector, this.workPackageTable, this);
    this.highlighting = new HighlightingRenderPass(this.injector, this.workPackageTable, this);
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
  protected appendRow(workPackage:WorkPackageResource,
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
