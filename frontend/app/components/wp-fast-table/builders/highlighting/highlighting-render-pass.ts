import {Injector} from '@angular/core';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';
import {WorkPackageRelationsService} from '../../../wp-relations/wp-relations.service';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {
  RelationColumnType,
  WorkPackageTableRelationColumnsService
} from '../../state/wp-table-relation-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {QueryColumn} from 'core-components/wp-query/query-column';
import {WorkPackageTableHighlightingService} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {States} from 'core-components/states.service';
import {ColorContrast} from 'core-components/a11y/color-contrast.functions';

export class HighlightingRenderPass {

  private readonly states:States = this.injector.get(States);
  private readonly wpTableHighlighting:WorkPackageTableHighlightingService = this.injector.get(WorkPackageTableHighlightingService);

  constructor(public readonly injector:Injector,
              private table:WorkPackageTable,
              private tablePass:PrimaryRenderPass) {

  }

  public render() {
    // If highlighting is done inline in attributes, skip
    if (!this.isApplicable) {
      return;
    }

    const highlightAttribute = this.wpTableHighlighting.current as 'status'|'priority';

    // Render for each original row, clone it since we're modifying the tablepass
    this.tablePass.renderedOrder.forEach((row:RowRenderInfo, position:number) => {

      // We only care for rows that are natural work packages
      if (!row.workPackage) {
        return;
      }

      // Get the loaded attribute of the WP
      const property = row.workPackage[highlightAttribute] as HalResource;
      const colored = this.wpTableHighlighting.getHighlightResource(highlightAttribute, property)

      if (colored.color) {
        const contrast = ColorContrast.getContrastingColor(colored.color);
        const element:HTMLElement = this.tablePass.tableBody.children[position] as HTMLElement;

        element.style.color = contrast;
        element.style.backgroundColor = colored.color;
      }

    });
  }

  private get isApplicable() {
    return !(this.wpTableHighlighting.isDefault || this.wpTableHighlighting.isDisabled);
  }
}
