import {Component, ElementRef, Inject, OnInit} from '@angular/core';
import {I18nToken, OpModalLocalsToken} from 'core-app/angular4-transition-utils';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {HalLink} from "core-app/modules/hal/hal-link/hal-link";

interface ExportLink extends HalLink {
  identifier:string;
}

@Component({
  template: require('!!raw-loader!./wp-table-export.modal.html')
})
export class WpTableExportModal extends OpModalComponent implements OnInit {

  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public $element:JQuery;
  public exportOptions:{ identifier:string, label:string, url:string }[];

  public text = {
    title: this.I18n.t('js.label_export'),
    closePopup: this.I18n.t('js.close_popup_title'),
  };

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly elementRef:ElementRef,
              readonly UrlParamsHelper:UrlParamsHelperService,
              readonly tableState:TableState,
              readonly wpTableColumns:WorkPackageTableColumnsService) {
    super(locals, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    this.tableState.results
      .valuesPromise()
      .then((results) => this.exportOptions = this.buildExportOptions(results!));
  }

  private buildExportOptions(results:WorkPackageCollectionResource) {
    return results.representations.map(format => {
      const link = format.$link as ExportLink;

      return {
        identifier: link.identifier,
        label: link.title,
        url: this.addColumnsToHref(format.href!)
      };
    });
  }

  private addColumnsToHref(href:string) {
    let columns = this.wpTableColumns.getColumns();

    let columnIds = columns.map(function (column) {
      return column.id;
    });

    let url = URI(href);
    // Remove current columns
    url.removeSearch('columns[]');
    url.addSearch('columns[]', columnIds);

    return url.toString();
  }

  protected get afterFocusOn():JQuery {
    return jQuery('#work-packages-settings-button');
  }

}
