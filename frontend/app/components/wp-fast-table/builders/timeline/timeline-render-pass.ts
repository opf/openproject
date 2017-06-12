import {PrimaryRenderPass, RenderedRow, SecondaryRenderPass} from '../primary-render-pass';
import {TimelineRowBuilder} from './timeline-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';

export class TimelineRenderPass implements SecondaryRenderPass {
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
    this.tablePass.renderedOrder.forEach((row:RenderedRow) => {
      const wpId = row.isWorkPackage ? row.belongsTo!.id : null;

      const secondary = this.timelineBuilder.build(wpId);
      this.tablePass.augmentSecondaryElement(secondary, row);

      this.timelineBody.appendChild(secondary);
    });
  }
}
