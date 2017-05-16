import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {TimelineRowBuilder} from '../timeline/timeline-row-builder';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {Subject} from 'rxjs';
import {rowClass} from '../../helpers/wp-table-row-helpers';

export interface RenderedRow {
  workPackageId?:string;
  classIdentifier:string;
  hidden:boolean;
}

export interface TableRenderResult {
  renderedOrder:RenderedRow[];
}

export abstract class TableRenderPass {
  public states:States;
  public I18n:op.I18n;

  /** Row builders */
  protected timelineBuilder:TimelineRowBuilder;

  /** The rendered order of rows of work package IDs or <null>, if not a work package row */
  public renderedOrder:RenderedRow[];

  /** Resulting table body */
  public tableBody:DocumentFragment;

  /** Resulting timeline body */
  public timelineBody:DocumentFragment;

  constructor(public stopExisting$:Subject<void>, public workPackageTable:WorkPackageTable) {
    $injectFields(this, 'states', 'I18n');
  }

  public render():this {
    // Prepare and reset the render pass
    this.prepare();
    // Render into the fragments
    this.stopExisting$.next();
    this.doRender();

    return this;
  }

  public get result():TableRenderResult {
    return {
      renderedOrder: this.renderedOrder
    };
  }

  protected prepare() {
    this.tableBody = document.createDocumentFragment();
    this.timelineBody = document.createDocumentFragment();
    this.timelineBuilder = new TimelineRowBuilder(this.stopExisting$, this.workPackageTable);
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
                      rowClasses:string[] = [],
                      hidden:boolean = false) {

    this.tableBody.appendChild(row);
    this.timelineBuilder.insert(workPackage, this.timelineBody, rowClasses);

    this.renderedOrder.push({
      workPackageId: workPackage.id.toString(),
      classIdentifier: rowClass(workPackage.id),
      hidden: hidden
    });
  }

  /**
   * Append a non-work package row to both containers
   * @param row HTMLElement to append
   * @param classIdentifer a unique identifier for the two rows (one each in table/timeline).
   * @param additionalClasses Additional classes to apply to the timeline row for mirroring purposes
   * @param hidden whether the row was rendered hidden
   */
  protected appendNonWorkPackageRow(row:HTMLElement, classIdentifer:string, additionalClasses:string[] = [], hidden:boolean = false) {
    row.classList.add(classIdentifer);
    this.tableBody.appendChild(row);
    this.timelineBuilder.insert(null, this.timelineBody, additionalClasses.concat([classIdentifer]));

    this.renderedOrder.push({
      classIdentifier: classIdentifer,
      hidden: hidden
    });
  }
}
