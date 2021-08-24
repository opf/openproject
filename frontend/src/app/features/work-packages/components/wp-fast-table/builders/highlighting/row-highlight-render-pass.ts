import { Injector } from '@angular/core';
import { PrimaryRenderPass, RowRenderInfo } from 'core-app/features/work-packages/components/wp-fast-table/builders/primary-render-pass';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export class HighlightingRenderPass {
  @InjectField() wpTableHighlighting:WorkPackageViewHighlightingService;

  @InjectField() querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
    private table:WorkPackageTable,
    private tablePass:PrimaryRenderPass) {

  }

  public render() {
    // If highlighting is done inline in attributes, skip
    if (!this.isApplicable) {
      return;
    }

    const highlightAttribute = this.wpTableHighlighting.current.mode;

    // Get the computed style to identify bright properties
    const styles = window.getComputedStyle(document.body);

    // Render for each original row, clone it since we're modifying the tablepass
    this.tablePass.renderedOrder.forEach((row:RowRenderInfo, position:number) => {
      // We only care for rows that are natural work packages
      if (!row.workPackage) {
        return;
      }

      // Get the loaded attribute of the WP
      const property = row.workPackage[highlightAttribute] as HalResource;

      // We only color rows that have an active attribute
      if (!property) {
        return;
      }

      const id = property.id!;
      const element:HTMLElement = this.tablePass.tableBody.children[position] as HTMLElement;
      element.classList.add(Highlighting.backgroundClass(highlightAttribute, id));
    });
  }

  private get isApplicable() {
    return !(this.wpTableHighlighting.isInline || this.wpTableHighlighting.isDisabled);
  }
}
