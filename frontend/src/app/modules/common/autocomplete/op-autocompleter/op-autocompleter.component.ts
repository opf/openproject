
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {AfterContentInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild, TemplateRef, ContentChild} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {AngularTrackingHelpers} from 'core-components/angular/tracking-functions';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {HalResourceSortingService} from 'core-app/modules/hal/services/hal-resource-sorting.service';
import {DropdownPosition, NgSelectComponent} from '@ng-select/ng-select';
import {APIV3Service} from 'core-app/modules/apiv3/api-v3.service';
import { DebouncedRequestSwitchmap, errorNotificationHandler } from 'core-app/helpers/rxjs/debounced-input-switchmap';
import { Observable, of, Subject } from 'rxjs';
import { HalResourceNotificationService } from 'core-app/modules/hal/services/hal-resource-notification.service';
import { CurrentProjectService } from 'core-app/components/projects/current-project.service';
import { ApiV3FilterBuilder, FilterOperator } from 'core-app/components/api/api-v3/api-v3-filter-builder';
import { debounceTime, distinctUntilChanged, map, switchMap, tap } from 'rxjs/operators';
import { APIv3ResourceCollection } from 'core-app/modules/apiv3/paths/apiv3-resource';
import { UserResource } from 'core-app/modules/hal/resources/user-resource';
import { APIv3UserPaths } from 'core-app/modules/apiv3/endpoints/users/apiv3-user-paths';
import { APIV3WorkPackagePaths } from 'core-app/modules/apiv3/endpoints/work_packages/api-v3-work-package-paths';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { UntilDestroyedMixin } from 'core-app/helpers/angular/until-destroyed.mixin';
import { GroupValueFn } from '@ng-select/ng-select/lib/ng-select.component';
import { OpAutocompleterOptionTemplateDirective } from "./Directives/op-autocompleter-option-template.directive";
import { OpAutocompleterLabelTemplateDirective } from "./Directives/op-autocompleter-label-template.directive";

export interface Conditions {name:string; operator:FilterOperator; values:unknown[]|boolean; }

@Component({
  selector: 'op-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl:'./op-autocompleter.component.html',
  styleUrls: ['./op-autocompleter.component.sass']
})


export class GeneralAutocompleterComponent extends UntilDestroyedMixin implements AfterContentInit {

  @Input() public conditions?:Conditions[];
  @Input() public resource:'work_packages' | 'users';
  @Input() public model?:any;
  @Input() public searchKey?:string;
  @Input() public defaultOpen?:boolean = false;
  @Input() public name?:string;
  @Input() public required?:boolean = false;
  @Input() public disabled?:string;
  @Input() public searchable?:boolean = true;
  @Input() public clearable?:boolean = true;
  @Input() public addTag?:boolean = false;
  @Input() public isOpen?:boolean = false;
  @Input() public clearSearchOnAdd?:boolean = true;
  @Input() public classes?:string;
  @Input() public multiple?:boolean = false;
  @Input() public bindLabel?:string;
  @Input() public bindValue?:string;
  @Input() public markFirst ? = true;
  @Input() public placeholder?:string;
  @Input() public notFoundText?:string;
  @Input() public typeToSearchText?:string;
  @Input() public addTagText?:string;
  @Input() public loadingText?:string;
  @Input() public clearAllText?:string;
  @Input() public appearance?:string;
  @Input() public dropdownPosition?:DropdownPosition = 'auto';
  @Input() public appendTo?:string;
  @Input() public loading?:boolean = false;
  @Input() public closeOnSelect?:boolean = true;
  @Input() public hideSelected?:boolean = false;
  @Input() public selectOnTab?:boolean = false;
  @Input() public openOnEnter?:boolean;
  @Input() public maxSelectedItems?:number;
  @Input() public groupBy?:string | Function;
  @Input() public groupValue?:GroupValueFn;
  @Input() public bufferAmount ? = 4;
  @Input() public virtualScroll?:boolean;
  @Input() public selectableGroup?:boolean = false;
  @Input() public selectableGroupAsModel?:boolean = true;
  @Input() public searchFn ? = null;
  @Input() public trackByFn ? = null;
  @Input() public clearOnBackspace?:boolean = true;
  @Input() public labelForId ? = null;
  @Input() public inputAttrs?:{ [key:string]:string } = {};
  @Input() public tabIndex?:number;
  @Input() public readonly?:boolean = false;
  @Input() public searchWhileComposing?:boolean = true;
  @Input() public minTermLength ? = 0;
  @Input() public editableSearchTerm?:boolean = false;
  @Input() public keyDownFn ? = (_:KeyboardEvent) => true;
  @Input() public hasDefaultContent:boolean;
  @Input() public typeahead?:Subject<string>;

  @Output() public onOpen = new EventEmitter<any>();
  @Output() public onClose = new EventEmitter<any>();
  @Output() public onChange = new EventEmitter<any>();
  @Output() public onFocus = new EventEmitter<any>();
  @Output() public onBlur = new EventEmitter<any>();
  @Output() public onSearch = new EventEmitter<{ term:string, items:any[] }>();
  @Output() public onKeydown = new EventEmitter<any>();
  @Output() public onClear = new EventEmitter<any>();
  @Output() public onAdd = new EventEmitter();
  @Output() public onRemove = new EventEmitter();
  @Output() public onScroll = new EventEmitter<{ start:number; end:number }>();
  @Output() public onScrollToEnd = new EventEmitter();

  public compareByHrefOrString = AngularTrackingHelpers.compareByHrefOrString;
  public active:Set<string>;
  public searchInput$ = new Subject<string>();

  public results$:Observable<HalResource[]> = this.searchInput$.pipe(
    debounceTime(250),
    distinctUntilChanged(),
    tap(() => this.isOpen = true),
    switchMap(queryString => this.loadAvailable(queryString))
  );

  public requests = new DebouncedRequestSwitchmap<string>(
    (searchTerm:string) =>  this.loadAvailable(searchTerm) ,
    errorNotificationHandler(this.halNotification),
    true
  );

  public isLoading = false;

  @ViewChild('ngSelectInstance', { static: true }) ngSelectInstance:NgSelectComponent;

  @ContentChild(OpAutocompleterOptionTemplateDirective, { read: TemplateRef })
  optionTemplate:TemplateRef<any>;

  @ContentChild(OpAutocompleterLabelTemplateDirective, { read: TemplateRef })
  labelTemplate:TemplateRef<any>;

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
    this.requests.input$.next('');
  }

  initialization() {
    this
    .requests
    .output$.pipe(
      this.untilDestroyed()
    )
    .subscribe((values:HalResource[]) => {
      this.cdRef.detectChanges();
    });
  }

  ngAfterContentInit():void {
    if (!this.ngSelectInstance) {
      return;
    }

    setTimeout(() => {
      this.ngSelectInstance.focus();
    }, 25);
  }

  public loadAvailable(matching:string):Observable<HalResource[]> {
    const filters:ApiV3FilterBuilder = this.createFilters(this.conditions ?? [], matching);

    if (matching === null || matching.length === 0) {
      this.isLoading = false;
      return of([]);
    }
    const filteredData = (this.apiV3Service[this.resource] as
      APIv3ResourceCollection<UserResource|WorkPackageResource, APIv3UserPaths|APIV3WorkPackagePaths>)
      .filtered(filters).get()
      .pipe(map(collection => collection.elements));

      filteredData.subscribe(() => this.isLoading = false);

    return filteredData;
  }

  protected createFilters(conditions:Conditions[], matching:string) {
    const filters = new ApiV3FilterBuilder();

    for (const condition of conditions) {
      filters.add(condition.name, condition.operator, condition.values);
    }
    if (matching) {
      filters.add(this.searchKey ?? '', '**', [matching]);
    }
    return filters;
  }

  public repositionDropdown() {
    if (this.ngSelectInstance) {
        const component = (this.ngSelectInstance) as any;
        if (component && component.dropdownPanel) {
          component.dropdownPanel._updatePosition();
        }
    }
  }

  public opened(val:any) {
    if (this.defaultOpen) {
      this.repositionDropdown();
    }
    else {
      this.onOpen.emit();
    }
  }

  public closed(val:any) {
    this.onClose.emit();
  }

  public changed(val:any) {
    this.onChange.emit(val);
  }

  public blured(val:any) {
    this.onBlur.emit(val);
  }

  public focused(val:any) {
    this.onFocus.emit(val);
  }

  public cleared(val:any) {
    this.onClear.emit(val);
  }

  public keydown(val:any) {
    this.onKeydown.emit(val);
  }
  public added(val:any) {
    this.onAdd.emit(val);
  }
  public removed(val:any) {
    this.onRemove.emit(val);
  }
  public scrolled(val:any) {
    this.onScroll.emit(val);
  }
  public scrolledToEnd(val:any) {
    this.onScrollToEnd.emit(val);
  }

}
