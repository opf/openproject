import { sortBy } from 'lodash-es';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC,
  QuerySortByResource,
} from 'core-app/features/hal/resources/query-sort-by-resource';

export class SortModalObject {
  constructor(public column:SortColumn,
    public direction:string) {
  }
}

export interface SortColumn {
  name:string;
  href:string | null;
}

export type SortingMode = 'automatic'|'manual';

@Component({
  templateUrl: './sort-by-tab.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WpTableConfigurationSortByTabComponent implements TabComponent, OnInit {
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  readonly cdRef = inject(ChangeDetectorRef);

  public text = {
    title: this.I18n.t('js.label_sort_by'),
    placeholder: this.I18n.t('js.placeholders.default'),
    sort_criteria_1: this.I18n.t('js.filter.sorting.criteria.one'),
    sort_criteria_2: this.I18n.t('js.filter.sorting.criteria.two'),
    sort_criteria_3: this.I18n.t('js.filter.sorting.criteria.three'),
    sorting_mode: {
      description: this.I18n.t('js.work_packages.table_configuration.sorting_mode.description'),
      automatic: this.I18n.t('js.work_packages.table_configuration.sorting_mode.automatic'),
      manually: this.I18n.t('js.work_packages.table_configuration.sorting_mode.manually'),
      warning: this.I18n.t('js.work_packages.table_configuration.sorting_mode.warning'),
    },
  };

  readonly availableDirections = [
    { href: QUERY_SORT_BY_ASC, name: this.I18n.t('js.label_ascending') },
    { href: QUERY_SORT_BY_DESC, name: this.I18n.t('js.label_descending') },
  ];

  public availableColumns:SortColumn[] = [];

  public allColumns:SortColumn[] = [];

  public sortationObjects:SortModalObject[] = [];

  public emptyColumn:SortColumn = { name: this.text.placeholder, href: null };

  public sortingMode:SortingMode = 'automatic';

  public manualSortColumn:SortColumn;

  public onSave() {
    let sortElements;
    if (this.sortingMode === 'automatic') {
      sortElements = this.sortationObjects.filter((object) => object.column !== null);
    } else {
      sortElements = [new SortModalObject(this.manualSortColumn, QUERY_SORT_BY_ASC)];
    }

    sortElements = sortElements.map((object) => this.getMatchingSort(object.column.href!, object.direction));
    this.wpTableSortBy.update(sortElements.filter((x):x is NonNullable<typeof x> => Boolean(x)));
  }

  ngOnInit() {
    this.wpTableSortBy
      .onReadyWithAvailable()
      .subscribe(() => {
        const allColumns:SortColumn[] = this.wpTableSortBy.available.filter(
          (sort:QuerySortByResource) => !sort.column.href!.endsWith('/parent'),
        ).map(
          (sort:QuerySortByResource) => ({ name: sort.column.name, href: sort.column.href }),
        );

        // For whatever reason, even though the UI doesn't implement it,
        // QuerySortByResources are doubled for each column (one for asc/desc direction)
        this.allColumns = allColumns.filter((col, index, self) => index === self.findIndex((other) => other.href === col.href));

        this.getManualSortingOption();

        this.wpTableSortBy.current.forEach((sort) => {
          if (!sort.column.href!.endsWith('/parent')) {
            this.sortationObjects.push(
              new SortModalObject({ name: sort.column.name, href: sort.column.href },
                sort.direction.href!),
            );
            if (sort.column.href === this.manualSortColumn.href) {
              this.updateSortingMode('manual');
            }
          }
        });

        this.updateUsedColumns();
        this.fillUpSortElements();
        this.cdRef.markForCheck();
      });
  }

  public updateSelection(sort:SortModalObject, selected:string | null) {
    sort.column = this.allColumns.find((column) => column.href === selected) ?? this.emptyColumn;
    this.updateUsedColumns();
  }

  public updateUsedColumns() {
    const usedColumns = this.sortationObjects
      .filter((o) => o.column !== null)
      .map((object:SortModalObject) => object.column);

    this.availableColumns = sortBy(this.allColumns.filter((col) => !usedColumns.some((used) => used.href === col.href)), 'name');
  }

  public updateSortingMode(mode:SortingMode) {
    this.sortingMode = mode;
  }

  private getMatchingSort(column:string, direction:string) {
    return this.wpTableSortBy.available.find((sort) => sort.column.href === column && sort.direction.href === direction);
  }

  private fillUpSortElements() {
    while (this.sortationObjects.length < 3) {
      this.sortationObjects.push(new SortModalObject(this.emptyColumn, QUERY_SORT_BY_ASC));
    }
  }

  private getManualSortingOption() {
    this.manualSortColumn = this.allColumns.find((e) => e.href!.endsWith('/manualSorting'))!;
    this.allColumns.splice(this.allColumns.indexOf(this.manualSortColumn), 1);
  }
}
