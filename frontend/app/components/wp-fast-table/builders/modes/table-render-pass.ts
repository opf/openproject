import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {TimelineRowBuilder} from '../timeline/timeline-row-builder';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {Subject} from 'rxjs';

export interface TableRenderResult {
  renderedOrder:(string|null)[];
}

export abstract class TableRenderPass {
  public states:States;
  public I18n:op.I18n;

  /** Row builders */
  protected timelineBuilder:TimelineRowBuilder;

  /** The rendered order of rows of work package IDs or <null>, if not a work package row */
  public renderedOrder:(string|null)[];

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
   * Append a new row a work package (or a virtual row) to both containers
   * @param workPackage The work package, if the row belongs to one
   * @param row HTMLElement to append
   * @param tableBody DocumentFragement to replace the table body
   * @param timelineBody DocumentFragment to replace the timeline
   * @param rowClasses Additional classes to apply to the timeline row for mirroring purposes
   */
  protected appendRow(workPackage:WorkPackageResourceInterface | null,
                      row:HTMLElement,
                      rowClasses:string[] = []) {

    this.tableBody.appendChild(row);
    this.timelineBuilder.insert(workPackage, this.timelineBody, rowClasses);

    if (workPackage) {
      this.renderedOrder.push(workPackage.id.toString());
    } else {
      this.renderedOrder.push(null);
    }
  }
}
