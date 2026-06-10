import { ChangeDetectionStrategy, Component, Injector, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {
  TabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import {
  DraggableOption,
} from 'core-app/shared/components/autocompleter/draggable-autocomplete/draggable-autocomplete.component';

@Component({
  templateUrl: './columns-tab.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WpTableConfigurationColumnsTabComponent implements TabComponent, OnInit {
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly wpTableColumns = inject(WorkPackageViewColumnsService);

  public availableColumnsOptions = this.wpTableColumns.all.map((c) => this.column2Like(c));

  public availableColumns = this.wpTableColumns.all;

  public availableColumnsMap:Record<string, QueryColumn> = _.keyBy(this.availableColumns, (c) => c.id);

  public selectedColumns:DraggableOption[] = this.wpTableColumns.getColumns().map((c) => this.column2Like(c));

  public selectedColumnMap:Record<string, boolean> = {};

  public text = {
    columnsHelp: this.I18n.t('js.work_packages.table_configuration.columns_help_text'),
    columnsLabel: this.I18n.t('js.label_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),

    inputPlaceholder: this.I18n.t('js.label_search_columns'),
    inputLabel: this.I18n.t('js.label_add_columns'),
    inputDragLabel: this.I18n.t('js.label_manage_columns'),
  };

  public onSave() {
    this.wpTableColumns.setColumnsById(this.selectedColumns.map((c) => c.id));
  }

  ngOnInit() {
    this.selectedColumns.forEach((c:DraggableOption) => {
      this.selectedColumnMap[c.id] = true;
    });
  }

  private column2Like(c:QueryColumn):DraggableOption {
    return { id: c.id, name: c.name };
  }

  updateSelected(selected:DraggableOption[]) {
    this.selectedColumns = selected;
  }
}
