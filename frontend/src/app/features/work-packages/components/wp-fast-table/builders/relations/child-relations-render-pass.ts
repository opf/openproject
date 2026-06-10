import { RowRenderInfo } from '../primary-render-pass';
import {
  RelationsRenderPass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/relations/relations-render-pass';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

export class ChildRelationsRenderPass extends RelationsRenderPass {
  renderType = 'child_relations';

  label = this.I18n.t('js.relation_labels.child');

  @LazyInject() apiV3Service:ApiV3Service;

  private loadingMissingTargets = false;

  public render() {
    // If no relation column active, skip this pass
    if (!this.isApplicable) {
      return;
    }

    // Render for each original row, clone it since we're modifying the tablepass
    const rendered = _.clone(this.tablePass.renderedOrder);
    const missingChildIds:string[] = [];

    rendered.forEach((row:RowRenderInfo) => {
      // We only care for rows that are natural work packages
      if (!row.workPackage) {
        return;
      }

      // If the work package has no children, ignore
      const { workPackage } = row;
      if (!workPackage.children?.length) {
        return;
      }

      // Only if the work package has anything expanded
      const expanded = this.wpTableRelationColumns.getExpandFor(workPackage.id!);
      if (expanded === undefined) {
        return;
      }

      const column = this.wpTableColumns.findById(expanded)!;

      // Render the child relations
      workPackage.children.forEach((child) => {
        const target = this.states.workPackages.get(child.id!).value;

        if (!target) {
          missingChildIds.push(child.id!);
          return;
        }

        // Build each relation row (currently sorted by order defined in API)
        const [relationRow] = this.relationRowBuilder.buildEmptyRelationRow(
          workPackage,
          target,
        );

        // Augment any data for the belonging work package row to it
        this.renderRelationRow(relationRow, row, this.label, column, workPackage, target, 'children');
      });
    });

    this.loadMissingTargets(missingChildIds);
  }

  public get isApplicable() {
    return this.wpTableColumns.hasChildRelationsColumn();
  }

  private loadMissingTargets(ids:string[]) {
    const uniqueIds = _.uniq(ids);

    if (uniqueIds.length === 0 || this.loadingMissingTargets) {
      return;
    }

    this.loadingMissingTargets = true;

    void this.apiV3Service.work_packages.requireAll(uniqueIds)
      .then(() => {
        this.loadingMissingTargets = false;
        this.tablePass.workPackageTable.redrawTable();
      })
      .catch(() => {
        this.loadingMissingTargets = false;
      });
  }
}
