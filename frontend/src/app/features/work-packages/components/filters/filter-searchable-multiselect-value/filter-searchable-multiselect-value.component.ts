import { NgSelectComponent } from '@ng-select/ng-select';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DebouncedRequestSwitchmap, errorNotificationHandler } from 'core-app/shared/helpers/rxjs/debounced-input-switchmap';
import { Observable } from 'rxjs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { map } from 'rxjs/operators';
import { APIv3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CachableAPIV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  AfterViewInit, ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component, EventEmitter, Input, NgZone, OnInit, Output, ViewChild,
} from '@angular/core';
import { compareByHrefOrString } from 'core-app/shared/helpers/angular/tracking-functions';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'filter-searchable-multiselect-value',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './filter-searchable-multiselect-value.component.html',
})
export class FilterSearchableMultiselectValueComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() public filter:QueryFilterInstanceResource;

  @Input() public shouldFocus = false;

  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  private _isEmpty:boolean;

  public _availableOptions:HalResource[] = [];

  public compareByHrefOrString = compareByHrefOrString;

  public active:Set<string>;

  public requests = new DebouncedRequestSwitchmap<string, HalResource>(
    (searchTerm:string) => this.loadAvailable(searchTerm),
    errorNotificationHandler(this.halNotification),
    true,
  );

  readonly text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  public get value() {
    return this.filter.values;
  }

  public get availableOptions() {
    return this._availableOptions;
  }

  public set availableOptions(val:HalResource[]) {
    this._availableOptions = this.halSorting.sort(val);
  }

  public get isEmpty():boolean {
    return this._isEmpty = this.value.length === 0;
  }

  @ViewChild('ngSelectInstance', { static: true }) ngSelectInstance:NgSelectComponent;

  constructor(readonly halResourceService:HalResourceService,
    readonly halSorting:HalResourceSortingService,
    readonly apiV3Service:APIV3Service,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    protected currentProject:CurrentProjectService,
    readonly halNotification:HalResourceNotificationService,
    readonly ngZone:NgZone) {
    super();
  }

  ngOnInit() {
    this.initialization();
    // Request an empty value to load warning early on
    this.requests.input$.next('');
  }

  ngAfterViewInit():void {
    if (this.ngSelectInstance && this.shouldFocus) {
      this.ngSelectInstance.focus();
    }
  }

  initialization() {
    this
      .requests
      .output$.pipe(
        this.untilDestroyed(),
      )
      .subscribe((values:HalResource[]) => {
        this.availableOptions = values;
        this.cdRef.detectChanges();
      });
  }

  public loadAvailable(matching:string):Observable<HalResource[]> {
    const filters:ApiV3FilterBuilder = this.createFilters(matching);
    const { href } = this.filter.currentSchema!.values!.allowedValues as any;

    const filteredData = (this.apiV3Service.collectionFromString(href) as
      APIv3ResourceCollection<HalResource, CachableAPIV3Resource>)
      .filtered(filters)
      .get()
      .pipe(map((collection) => collection.elements));

    return filteredData;
  }

  protected createFilters(matching:string) {
    const filters = new ApiV3FilterBuilder();

    if (matching) {
      filters.add('subjectOrId', '**', [matching]);
    }

    return filters;
  }

  public setValues(val:any) {
    this.filter.values = val.length > 0 ? (Array.isArray(val) ? val : [val]) : [] as HalResource[];
    this.filterChanged.emit(this.filter);
    this.requests.input$.next('');
    this.cdRef.detectChanges();
  }

  public repositionDropdown() {
    if (this.ngSelectInstance) {
      const component = (this.ngSelectInstance) as any;
      if (component && component.dropdownPanel) {
        this.ngZone.runOutsideAngular(() => {
          setTimeout(() => {
            component.dropdownPanel._updatePosition();
          }, 25);
        });
      }
    }
  }
}
