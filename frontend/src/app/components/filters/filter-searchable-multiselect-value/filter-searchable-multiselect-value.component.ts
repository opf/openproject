
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { QueryFilterInstanceResource } from 'core-app/modules/hal/resources/query-filter-instance-resource';
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { AngularTrackingHelpers } from 'core-components/angular/tracking-functions';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { HalResourceSortingService } from 'core-app/modules/hal/services/hal-resource-sorting.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { APIV3Service } from 'core-app/modules/apiv3/api-v3.service';
import { DebouncedRequestSwitchmap, errorNotificationHandler } from 'core-app/helpers/rxjs/debounced-input-switchmap';
import { ValueOption } from 'core-app/modules/fields/edit/field-types/select-edit-field.component';
import { Observable } from 'rxjs';
import { HalResourceNotificationService } from 'core-app/modules/hal/services/hal-resource-notification.service';
import { CurrentProjectService } from 'core-app/components/projects/current-project.service';
import { ApiV3FilterBuilder, FilterOperator } from 'core-app/components/api/api-v3/api-v3-filter-builder';
import { map } from 'rxjs/operators';
import { APIv3ResourceCollection } from 'core-app/modules/apiv3/paths/apiv3-resource';
import { UserResource } from 'core-app/modules/hal/resources/user-resource';
import { APIv3UserPaths } from 'core-app/modules/apiv3/endpoints/users/apiv3-user-paths';
import { APIV3WorkPackagePaths } from 'core-app/modules/apiv3/endpoints/work_packages/api-v3-work-package-paths';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { UntilDestroyedMixin } from 'core-app/helpers/angular/until-destroyed.mixin';
import { CachableAPIV3Resource } from "core-app/modules/apiv3/cache/cachable-apiv3-resource";
export interface FilterConditions {name:string; operator:FilterOperator; values:unknown[]|boolean; }

@Component({
  selector: 'filter-searchable-multiselect-value',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl:'./filter-searchable-multiselect-value.component.html'
})


export class FilterSearchableMultiselectValueComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() public filter:QueryFilterInstanceResource;
  @Input() public shouldFocus = false;
  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  private _isEmpty:boolean;
  public _availableOptions:HalResource[] = [];
  public compareByHrefOrString = AngularTrackingHelpers.compareByHrefOrString;
  public active:Set<string>;
  public requests = new DebouncedRequestSwitchmap<string, ValueOption>(
    (searchTerm:string) => this.loadAvailable(searchTerm),
    errorNotificationHandler(this.halNotification),
    true
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
              readonly halNotification:HalResourceNotificationService) {
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
        this.untilDestroyed()
      )
      .subscribe((values:HalResource[]) => {
        this.availableOptions = values;
        this.cdRef.detectChanges();
      });
  }

  public loadAvailable(matching:string):Observable<HalResource[]> {
    const filters:ApiV3FilterBuilder = this.createFilters(matching);
    const href = (this.filter.currentSchema!.values!.allowedValues as any).$href;

    const filteredData = (this.apiV3Service.collectionFromString(href) as
      APIv3ResourceCollection<HalResource, CachableAPIV3Resource>)
      .filtered(filters)
      .get()
      .pipe(map(collection => collection.elements));

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
        component.dropdownPanel._updatePosition();
      }
    }
  }
}
