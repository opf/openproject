import {Injector} from '@angular/core';
import {PrimaryRenderPass, RowRenderInfo} from "core-components/wp-fast-table/builders/primary-render-pass";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";

export class HighlightingRenderPass {

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

    const highlightAttribute = this.wpTableHighlighting.current;

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

      const id = property.getId();
      const element:HTMLElement = this.tablePass.tableBody.children[position] as HTMLElement;
      element.classList.add(Highlighting.rowClass(highlightAttribute, id));

      // If the applied color is bright, also apply the '-bright-row' class
      if (Highlighting.isBright(styles, highlightAttribute, id)) {
        element.classList.add('-bright-row');
      }
    });
  }

  private get isApplicable() {
    return !(this.wpTableHighlighting.isInline || this.wpTableHighlighting.isDisabled);
  }
}
