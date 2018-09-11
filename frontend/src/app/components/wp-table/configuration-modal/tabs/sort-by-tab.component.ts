import {Component, Inject, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC,
  QuerySortByResource
} from 'core-app/modules/hal/resources/query-sort-by-resource';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {take} from 'rxjs/operators';

export class SortModalObject {
  constructor(public column:SortColumn,
              public direction:string) {
  }
}

export interface SortColumn {
  name:string;
  href:string | null;
}

@Component({
  templateUrl: './sort-by-tab.component.html'
})
export class WpTableConfigurationSortByTab implements TabComponent {

  public text = {
    title: this.I18n.t('js.label_sort_by'),
    placeholder: this.I18n.t('js.placeholders.default'),
    sort_criteria_1: this.I18n.t('js.filter.sorting.criteria.one'),
    sort_criteria_2: this.I18n.t('js.filter.sorting.criteria.two'),
    sort_criteria_3: this.I18n.t('js.filter.sorting.criteria.three'),
  };

  readonly availableDirections = [
    {$href: QUERY_SORT_BY_ASC, name: this.I18n.t('js.label_ascending')},
    {$href: QUERY_SORT_BY_DESC, name: this.I18n.t('js.label_descending')}
  ];

  public availableColumns:SortColumn[] = [];
  public allColumns:SortColumn[] = [];
  public sortationObjects:SortModalObject[] = [];
  public emptyColumn:SortColumn = {name: this.text.placeholder, href: null};

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableSortBy:WorkPackageTableSortByService) {

  }

  public onSave() {
    let sortElements =
      this.sortationObjects
        .filter(object => object.column !== null)
        .map(object => this.getMatchingSort(object.column.href!, object.direction));

    this.wpTableSortBy.set(_.compact(sortElements));
  }

  ngOnInit() {
    this.wpTableSortBy
      .state
      .values$()
      .pipe(take(1))
      .toPromise()
      .then(() => {
        let allColumns:SortColumn[] = this.wpTableSortBy.available.filter(
          (sort:QuerySortByResource) => {
            return !sort.column.$href!.endsWith('/parent');
          }
        ).map(
          (sort:QuerySortByResource) => {
            return {name: sort.column.name, href: sort.column.$href};
          }
        );

        // For whatever reason, even though the UI doesnt implement it,
        // QuerySortByResources are doubled for each column (one for asc/desc direction)
        this.allColumns = _.uniqBy(allColumns, 'href');

        _.each(this.wpTableSortBy.currentSortBys, sort => {
          if (!sort.column.$href!.endsWith('/parent')) {
            this.sortationObjects.push(
              new SortModalObject({name: sort.column.name, href: sort.column.$href},
                sort.direction.$href!)
            );
          }
        });

        this.updateUsedColumns();
        this.fillUpSortElements();
      });
  }

  public updateSelection(sort:SortModalObject, selected:string | null) {
    sort.column = _.find(this.allColumns, (column) => column.href === selected) || this.emptyColumn;
    this.updateUsedColumns();
  }

  public updateUsedColumns() {
    let usedColumns = this.sortationObjects
      .filter(o => o.column !== null)
      .map((object:SortModalObject) => object.column);

    this.availableColumns = _.sortBy(_.differenceBy(this.allColumns, usedColumns, 'href'), 'name');
  }

  private getMatchingSort(column:string, direction:string) {
    return _.find(this.wpTableSortBy.available, sort => {
      return sort.column.$href === column && sort.direction.$href === direction;
    });
  }

  private fillUpSortElements() {
    while (this.sortationObjects.length < 3) {
      this.sortationObjects.push(new SortModalObject(this.emptyColumn, QUERY_SORT_BY_ASC));
    }
  }
}
