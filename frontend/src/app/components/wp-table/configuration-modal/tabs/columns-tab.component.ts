import {Component, Inject, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {QueryColumn} from 'core-components/wp-query/query-column';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {cloneHalResourceCollection} from 'core-app/modules/hal/helpers/hal-resource-builder';

@Component({
  templateUrl: './columns-tab.component.html'
})
export class WpTableConfigurationColumnsTab implements TabComponent {

  public availableColumns = this.wpTableColumns.all;
  public unusedColumns = this.wpTableColumns.unused;
  public selectedColumns = cloneHalResourceCollection<QueryColumn>(this.wpTableColumns.getColumns());

  public impaired = this.ConfigurationService.accessibilityModeEnabled();
  public selectedColumnMap:{ [id:string]:boolean } = {};
  public eeShowBanners:boolean = false;
  public text = {

    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),

    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link')
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly ConfigurationService:ConfigurationService) {
  }

  public onSave() {
    this.wpTableColumns.setColumns(this.selectedColumns);
  }

  public setSelectedColumn(column:QueryColumn) {
    if (this.selectedColumnMap[column.id]) {
      this.selectedColumns.push(column);
    }
    else {
      _.remove(this.selectedColumns, (c:QueryColumn) => c.id === column.id);
    }
  }

  ngOnInit() {
    this.eeShowBanners = angular.element('body').hasClass('ee-banners-visible');
    this.selectedColumns.forEach((column:QueryColumn) => {
      this.selectedColumnMap[column.id] = true;
    });
  }
}
