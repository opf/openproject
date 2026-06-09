import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HighlightingRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/row-highlight-render-pass';
import { DragDropHandleRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-render-pass';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { timeOutput } from 'core-app/shared/helpers/debug_output';
import { TimelineRenderPass } from './timeline/timeline-render-pass';
import { SingleRowBuilder } from './rows/single-row-builder';
import { RelationRenderInfo, RelationsRenderPass } from './relations/relations-render-pass';
import { WorkPackageTable } from '../wp-fast-table';
import {
  ChildRelationsRenderPass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/relations/child-relations-render-pass';
import { getNodeIndex } from 'core-app/shared/helpers/dom-helpers';
import invariant from 'tiny-invariant';

export type RenderedRowType = 'primary'|'relations'|'child_relations';

export interface RowRenderInfo {
  // The rendered row
  element:HTMLTableRowElement;
  // Unique class name as an identifier to uniquely identify the row in both table and timeline
  classIdentifier:string;
  // Additional classes to be added by any secondary render passes
  additionalClasses:string[];
  // If this row is a work package, contains a reference to the rendered WP
  workPackage:WorkPackageResource|null;
  // If this is an additional row not present, this contains a reference to the WP
  // it originated from
  belongsTo?:WorkPackageResource;
  // The type of row this was rendered from
  renderType:RenderedRowType;
  // Marks if the row is currently hidden to the user
  hidden:boolean;
  // Additional data by the render passes
  /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
  data?:any;
}

export abstract class PrimaryRenderPass {
  @LazyInject() halEditing:HalResourceEditingService;

  @LazyInject() states:States;

  @LazyInject() I18n!:I18nService;

  /** The rendered order of rows of work package IDs or <null>, if not a work package row */
  public renderedOrder:RowRenderInfo[];

  /** Resulting table body */
  public tableBody:DocumentFragment;

  /** Additional render pass that handles timeline rendering */
  public timeline:TimelineRenderPass;

  /** Additional render pass that handles table relation rendering */
  public relations:RelationsRenderPass;

  /** Additional render pass that handles table child relation rendering */
  public childRelations:ChildRelationsRenderPass;

  /** Additional render pass that handles drag'n'drop handle rendering */
  public dragDropHandle:DragDropHandleRenderPass;

  /** Additional render pass that handles highlighting of rows */
  public highlighting:HighlightingRenderPass;

  constructor(
public readonly injector:Injector,
    public workPackageTable:WorkPackageTable,
    public rowBuilder:SingleRowBuilder,
) {
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

      // Post render
      this.postRender();
    });

    // Render subsequent passes
    // that may modify the structure of the table
    this.highlighting.render();

    timeOutput('Relations render pass', () => {
      this.relations.render();
      this.childRelations.render();
    });

    timeOutput('Drag handle render pass', () => {
      this.dragDropHandle.render();
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
    const oldRow = body.querySelector<HTMLTableRowElement>(`.${row.classIdentifier}`)!;
    let replacement:HTMLElement|null = null;

    switch (row.renderType) {
      case 'relations':
        replacement = this.relations.refreshRelationRow(row as RelationRenderInfo, workPackage, oldRow);
        break;
      case 'child_relations':
        replacement = this.childRelations.refreshRelationRow(row as RelationRenderInfo, workPackage, oldRow);
        break;
      default:
        replacement = this.rowBuilder.refreshRow(workPackage, oldRow);
        break;
    }

    if (replacement !== null && oldRow) {
      oldRow.replaceWith(replacement);
    }
  }

  public get result():RenderedWorkPackage[] {
    return this.renderedOrder.map((row) => ({
      classIdentifier: row.classIdentifier,
      workPackageId: row.workPackage ? row.workPackage.id : null,
      hidden: row.hidden,
    }));
  }

  /**
   * Splice a row into a specific location of the current render pass through the given selector.
   *
   * 1. Insert into the document fragment after the last match of the selector
   * 2. Splice into the renderedOrder array.
   */
  public spliceRow(row:HTMLTableRowElement, selector:string, renderedInfo:RowRenderInfo) {
    // Insert into table using the selector
    const matches = this.tableBody.querySelectorAll(selector);
    invariant(matches.length, `No matches found for selector: ${selector}`);

    // If it matches multiple, select the last element
    const target = matches[matches.length - 1];

    // Insert the new row AFTER the target
    target.parentNode!.insertBefore(row, target.nextSibling);

    // Splice the renderedOrder at this exact location
    const index = getNodeIndex(target);
    this.renderedOrder.splice(index + 1, 0, renderedInfo);
  }

  protected prepare() {
    this.timeline = new TimelineRenderPass(this.injector, this.workPackageTable, this);
    this.relations = new RelationsRenderPass(this.injector, this.workPackageTable, this);
    this.childRelations = new ChildRelationsRenderPass(this.injector, this.workPackageTable, this);
    this.dragDropHandle = new DragDropHandleRenderPass(this.injector, this.workPackageTable, this);
    this.highlighting = new HighlightingRenderPass(this.injector, this.workPackageTable, this);
    this.tableBody = document.createDocumentFragment();
    this.renderedOrder = [];
  }

  /**
   * The actual render function of this renderer.
   */
  protected abstract doRender():void;

  /**
   * Post render shared among all sub passes
   */
  protected postRender():void {
    if (this.renderedOrder.length === 0 && this.workPackageTable.renderPlaceholderRow) {
      this.tableBody.appendChild(this.rowBuilder.placeholderRow);
    }
  }

  /**
   * Append a work package row to both containers
   * @param workPackage The work package, if the row belongs to one
   * @param row HTMLElement to append
   * @param rowClasses Additional classes to apply to the timeline row for mirroring purposes
   * @param hidden whether the row was rendered hidden
   */
  protected appendRow(
workPackage:WorkPackageResource,
    row:HTMLTableRowElement,
    additionalClasses:string[] = [],
    hidden = false,
) {
    this.tableBody.appendChild(row);

    this.renderedOrder.push({
      classIdentifier: this.rowBuilder.classIdentifier(workPackage),
      additionalClasses,
      workPackage,
      renderType: 'primary',
      element: row,
      hidden,
    });
  }

  /**
   * Append a non-work package row to both containers
   * @param row HTMLElement to append
   * @param classIdentifer a unique identifier for the two rows (one each in table/timeline).
   * @param hidden whether the row was rendered hidden
   */
  protected appendNonWorkPackageRow(
row:HTMLTableRowElement,
    classIdentifer:string,
    additionalClasses:string[] = [],
    hidden = false,
) {
    row.classList.add(classIdentifer);
    this.tableBody.appendChild(row);

    this.renderedOrder.push({
      element: row,
      classIdentifier: classIdentifer,
      additionalClasses,
      workPackage: null,
      renderType: 'primary',
      hidden,
    });
  }
}
