import { WorkPackageRelationsService } from 'core-app/components/wp-relations/wp-relations.service';
import { WorkPackageTimelineTableController } from 'core-app/components/wp-table/timeline/container/wp-timeline-container.directive';
import { calculatePositionValueForDayCountingPx, RenderInfo, TimelineViewParameters } from 'core-app/components/wp-table/timeline/wp-timeline';
import jsPDF from 'jspdf';
import { Moment } from 'moment';
import { computeXAndWidth, ExportTimelineConfig, getRowY, isMilestone } from './ExportTimelineService';

export function drawRelations(doc:jsPDF,
                              vp:TimelineViewParameters,
                              wpRelations:WorkPackageRelationsService,
                              workPackageTimelineTableController:WorkPackageTimelineTableController,
                              config:ExportTimelineConfig) {
  let workPackageIdOrder = workPackageTimelineTableController.workPackageIdOrder;

  workPackageIdOrder.forEach(workPackage => {
    const wpId = workPackage.workPackageId;

    // Ignore extra rows not tied to a work package
    if (!wpId) {
      return;
    }

    const workPackageWithRelation = wpRelations.state(wpId);
    if (_.isNil(workPackageWithRelation)) {
      return;
    }

    const relations = _.values(workPackageWithRelation.value!);
    const relationsList = _.values(relations);
    relationsList.forEach(relation => {

      if (!(relation.type === 'precedes'
        || relation.type === 'follows')) {
        return;
      }

      const involved = relation.ids;

      const startCells = workPackageTimelineTableController.workPackageCells(involved.to);
      const endCells = workPackageTimelineTableController.workPackageCells(involved.from);
    
      // If either sources or targets are not rendered, ignore this relation
      if (startCells.length === 0 || endCells.length === 0) {
        return;
      }
    
      // Now, render all sources to all targets
      startCells.forEach((startCell) => {
        const idxFrom = workPackageTimelineTableController.workPackageIndex(startCell.classIdentifier);
        endCells.forEach((endCell) => {
          const idxTo = workPackageTimelineTableController.workPackageIndex(endCell.classIdentifier);
          
          const rowFrom = workPackageIdOrder[idxFrom];
          const rowTo = workPackageIdOrder[idxTo];

          // If any of the targets are hidden in the table, skip
          if (!(rowFrom && rowTo) || (rowFrom.hidden || rowTo.hidden)) {
            return;
          }

          // Skip if relations cannot be drawn between these cells
          if (!startCell.canConnectRelations() || !endCell.canConnectRelations()) {
            return;
          }

          // Get X values
          var dayLenght = calculatePositionValueForDayCountingPx(vp, 1);
          var [startDate, dueDate] = getStartAndDueDate(startCell.latestRenderInfo);
          var {x, w} = computeXAndWidth(startCell.latestRenderInfo, startDate, dueDate);
          var startX = x + w + config.nameColumnSize;
          var startY = getRowY(config, idxFrom) + config.lineHeight / 2;
          var [startDate, dueDate] = getStartAndDueDate(endCell.latestRenderInfo);
          var {x, w} = computeXAndWidth(endCell.latestRenderInfo, startDate, dueDate);
          var targetX = x + config.nameColumnSize;
          var targetY = getRowY(config, idxTo) + config.lineHeight / 2;

          // Vertical direction
          const directionY:'toUp'|'toDown' = idxFrom < idxTo ? 'toDown' : 'toUp';

          // Horizontal direction
          const directionX:'toLeft'|'beneath'|'toRight' =
            targetX > startX ? 'toRight' : targetX < startX ? 'toLeft' : 'beneath';
          
          let halfDay = dayLenght / 2;
          if (directionX === 'toLeft') {
            startX += halfDay;
            targetX -= halfDay;
          } else {
            startX -= halfDay;
            targetX += halfDay;
          }

          // start
          if (!startCell) {
            return;
          }

          doc.setDrawColor(config.relationLineColor);
          // Draw the first line next to the bar/milestone element
          doc.line(startX, startY, targetX, startY);

          // Draw vertical line between rows
          doc.line(targetX, startY, targetX, targetY);

        });
      });
    });

  });
}

function getStartAndDueDate(renderInfo:RenderInfo): Array<Moment> {
  if (isMilestone(renderInfo)) {
    return [
      moment(renderInfo.change.projectedResource.date),
      moment(renderInfo.change.projectedResource.date),
    ]
  } else {
    return [
      moment(renderInfo.change.projectedResource.startDate),
      moment(renderInfo.change.projectedResource.dueDate),
    ]
  }
}
