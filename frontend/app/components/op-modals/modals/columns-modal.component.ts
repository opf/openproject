import {Component, ElementRef, Inject, OnInit} from '@angular/core';
import {I18nToken, OpModalLocalsToken} from 'core-app/angular4-transition-utils';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {QueryColumn} from 'core-components/wp-query/query-column';
import {ConfigurationService} from 'core-components/common/config/configuration.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';

@Component({
  template: require('!!raw-loader!./columns-modal.component.html')
})
export class ColumnsModalComponent extends OpModalComponent {

  /* Close on escape? */
  public closeOnEscape = false;

  /* Close on outside click */
  public closeOnOutsideClick = false;

  public $element:JQuery;

  public text = {
    closePopup: this.I18n.t('js.close_popup_title'),
    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),
    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),
    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link')
  };


  public availableColumns = this.wpTableColumns.all;
  public unusedColumns = this.wpTableColumns.unused;
  public selectedColumns = angular.copy(this.wpTableColumns.getColumns());

  public impaired = this.ConfigurationService.accessibilityModeEnabled();
  public selectedColumnMap:{ [id:string]: boolean } = {};

  public eeShowBanners:boolean;



// //hack to prevent dragging of close icons
// $timeout(() => {
//   angular.element('.columns-modal-content .ui-select-match-close').on('dragstart', event => {
//     event.preventDefault();
//   });
// });
//
// $scope.$on('uiSelectSort:change', (event:any, args:any) => {
//   vm.selectedColumns = args.array;
// });


  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly ConfigurationService:ConfigurationService,
              readonly elementRef:ElementRef) {
            super(locals, elementRef);
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.impaired = true; // TODO
    this.eeShowBanners = angular.element('body').hasClass('ee-banners-visible');

    if (this.impaired) {
      this.selectedColumns.forEach((column:QueryColumn) => {
        this.selectedColumnMap[column.id] = true;
      });
    }
  }

  public updateSelectedColumns() {
    this.wpTableColumns.setColumns(this.selectedColumns);
    this.service.close();
  }

/**
 * When a column is removed from the selection it becomes unused and hence available for
 * selection again. When a column is added to the selection it becomes used and is
 * therefore unavailable for selection.
 *
 * This function updates the unused columns according to the currently selected columns.
 *
 * @param selectedColumns Columns currently selected through the multi select box.
 */
  public updateUnusedColumns(selectedColumns:QueryColumn[]) {
    this.unusedColumns = _.differenceBy(this.availableColumns, selectedColumns, '$href');
  }

  public setSelectedColumn(column:QueryColumn) {
    if (this.selectedColumnMap[column.id]) {
      this.selectedColumns.push(column);
    }
    else {
      _.remove(this.selectedColumns, (c:QueryColumn) => c.id === column.id);
    }
  }

  /**
   * Called when the user attempts to close the modal window.
   * The service will close this modal if this method returns true
   * @returns {boolean}
   */
  public onClose():boolean {
    this.afterFocusOn.focus();
    return true;
  }

  public onOpen(modalElement:JQuery) {
  }

  protected get afterFocusOn():JQuery {
    return this.$element;
  }
}
