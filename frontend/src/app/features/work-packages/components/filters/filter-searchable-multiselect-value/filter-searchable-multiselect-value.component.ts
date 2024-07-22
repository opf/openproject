import { NgSelectComponent } from '@ng-select/ng-select';
import {
  Observable,
  of,
} from 'rxjs';
import {
  map,
  shareReplay,
  switchMap,
  withLatestFrom,
} from 'rxjs/operators';
import { take } from 'rxjs/internal/operators/take';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';

import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { compareByHref } from 'core-app/shared/helpers/angular/tracking-functions';
import { MAGIC_FILTER_AUTOCOMPLETE_PAGE_SIZE } from 'core-app/core/apiv3/helpers/get-paginated-results';

@Component({
  selector: 'op-filter-searchable-multiselect-value',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './filter-searchable-multiselect-value.component.html',
})
export class FilterSearchableMultiselectValueComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public filter:QueryFilterInstanceResource;

  @Input() public shouldFocus = false;

  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  private meValue = this.halResourceService.createHalResource({
    _links: {
      self: {
        href: this.apiV3Service.users.me.path,
        title: this.I18n.t('js.label_me'),
      },
    },
  }, true);

  autocompleterFn = (searchTerm:string):Observable<HalResource[]> => this.autocomplete(searchTerm);

  initialRequest$:Observable<CollectionResource>;

  itemTracker = (item:HalResource):string => item.href || item.id || item.name;

  compareByHref = compareByHref;

  resourceType:string|null = null;

  readonly text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  public get value():string[]|HalResource[] {
    return this.filter.values;
  }

  @ViewChild('ngSelectInstance', { static: true }) ngSelectInstance:NgSelectComponent;

  constructor(
    readonly halResourceService:HalResourceService,
    readonly apiV3Service:ApiV3Service,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    protected currentProject:CurrentProjectService,
    protected currentUser:CurrentUserService,
    readonly halNotification:HalResourceNotificationService,
  ) {
    super();
  }

  ngOnInit():void {
    if (this.filter.id === 'id') {
      this.resourceType = 'work_packages';
    }

    this.initialRequest$ = this
      .loadCollection('')
      .pipe(
        shareReplay(1),
      );
  }

  private autocomplete(matching:string):Observable<HalResource[]> {
    return this
      .initialRequest$
      .pipe(
        switchMap((initialLoad) => {
          // If we already loaded all values, just compare in the frontend
          if (initialLoad.count === initialLoad.total) {
            return this.matchingItems(initialLoad.elements, matching);
          }

          // Otherwise, request the matching API call
          return this
            .loadCollection(matching)
            .pipe(
              switchMap((collection) => this.withMeValue(matching, collection.elements)),
            );
        }),
      );
  }

  matchingItems(elements:HalResource[], matching:string):Observable<HalResource[]> {
    let filtered:HalResource[];

    if (matching === '' || !matching) {
      filtered = elements;
    } else {
      const lowered = matching.toLowerCase();
      filtered = elements.filter((el) => (el.id as string).includes(lowered) || el.name.toLowerCase().includes(lowered));
    }

    return this.withMeValue(matching, filtered);
  }

  private loadCollection(matching:string):Observable<CollectionResource> {
    const filters:ApiV3FilterBuilder = this.createFilters(matching);

    return (this.apiV3Service.collectionFromString(this.allowedValuesLink) as
      ApiV3ResourceCollection<HalResource, ApiV3Resource>)
      .filtered(filters, { pageSize: `${MAGIC_FILTER_AUTOCOMPLETE_PAGE_SIZE}` })
      .get();
  }

  private createFilters(matching:string):ApiV3FilterBuilder {
    const filters = new ApiV3FilterBuilder();

    if (matching) {
      filters.add('typeahead', '**', [matching]);
    }

    return filters;
  }

  public setValues(val:string|HalResource|HalResource[]) {
    let values:string[]|HalResource[];

    if (typeof val === 'string') {
      values = val.length > 0 ? [val] : [];
    } else {
      values = Array.isArray(val) ? val : [val];
    }

    this.filter.values = values;
    this.filterChanged.emit(this.filter);
    this.cdRef.detectChanges();
  }

  private get allowedValuesLink():string {
    /* eslint-disable-next-line @typescript-eslint/no-non-null-assertion */
    const { href } = this.filter.currentSchema!.values!.allowedValues as { href:string };

    return href;
  }

  private withMeValue(matching:string, elements:HalResource[]):Observable<HalResource[]> {
    if (!this.isUserResource || (!!matching && matching !== 'me')) {
      return of(elements);
    }

    return this
      .currentUser
      .isLoggedIn$
      .pipe(
        take(1),
        withLatestFrom(this.currentUser.user$),
        map(([logged, user]) => {
          if (logged && user) {
            return [this.meValue].concat(elements);
          }

          return elements;
        }),
      );
  }

  private get isUserResource() {
    const type = _.get(this.filter.currentSchema, 'values.type', null) as string;
    return type && type.indexOf('User') > 0;
  }
}
