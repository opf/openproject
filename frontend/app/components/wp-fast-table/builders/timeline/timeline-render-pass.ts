import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {TimelineRowBuilder} from './timeline-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';

export class TimelineRenderPass {
  /** Row builders */
  protected timelineBuilder:TimelineRowBuilder;

  /** Resulting timeline body */
  public timelineBody:DocumentFragment;

  constructor(private table:WorkPackageTable, private tablePass:PrimaryRenderPass) {
  }

  public render() {
    // Prepare and reset the render pass
    this.timelineBody = document.createDocumentFragment();
    this.timelineBuilder = new TimelineRowBuilder(this.table);

    // Render into timeline fragment
    this.tablePass.renderedOrder.forEach((row:RowRenderInfo) => {
      const wpId = row.workPackage ? row.workPackage.id : null;

      const secondary = this.timelineBuilder.build(wpId);
      secondary.classList.add(row.classIdentifier, `${row.classIdentifier}-timeline`, ...row.additionalClasses);
      this.timelineBody.appendChild(secondary);
    });
  }
}
