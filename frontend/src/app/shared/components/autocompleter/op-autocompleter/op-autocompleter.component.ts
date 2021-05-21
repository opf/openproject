import {HalResource} from 'core-app/core/hal/resources/hal-resource';
import {AfterContentInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild, TemplateRef, ContentChild, AfterViewInit, NgZone} from '@angular/core';
import {I18nService} from 'core-app/core/i18n/i18n.service';
import {AngularTrackingHelpers} from 'core-app/shared/helpers/angular/tracking-functions';
import {HalResourceService} from 'core-app/core/hal/services/hal-resource.service';
import {HalResourceSortingService} from 'core-app/core/hal/services/hal-resource-sorting.service';
import {DropdownPosition, NgSelectComponent} from '@ng-select/ng-select';
import { Observable, Subject } from 'rxjs';
import { HalResourceNotificationService } from 'core-app/core/hal/services/hal-resource-notification.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { GroupValueFn } from '@ng-select/ng-select/lib/ng-select.component';
import { OpAutocompleterOptionTemplateDirective } from "./directives/op-autocompleter-option-template.directive";
import { OpAutocompleterLabelTemplateDirective } from "./directives/op-autocompleter-label-template.directive";
import { OpAutocompleterHeaderTemplateDirective } from "./directives/op-autocompleter-header-template.directive";
import { OpAutocompleterService } from "./services/op-autocompleter.service";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";

@Component({
  selector: 'op-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl:'./op-autocompleter.component.html',
  styleUrls: ['./op-autocompleter.component.sass'],
  providers: [OpAutocompleterService]
})
// It is component that you can use whenever you need an autocompleter
// it has all inputs and outputs of ng-select
// in order to use it, you only need to pass the data type and its filters
// you also can change the value of ng-select default options by changing @inputs and @outputs
export class OpAutocompleterComponent extends UntilDestroyedMixin implements AfterViewInit{

  @Input() public filters?:IAPIFilter[];
  @Input() public resource:resource;
  @Input() public model?:any;
  @Input() public searchKey?:string;
  @Input() public defaulData?:boolean = false;
  @Input() public name?:string;
  @Input() public required?:boolean = false;
  @Input() public disabled?:string;
  @Input() public searchable?:boolean = true;
  @Input() public clearable?:boolean = true;
  @Input() public addTag?:boolean = false;

  @Input() public clearSearchOnAdd?:boolean = true;
  @Input() public classes?:string;
  @Input() public multiple?:boolean = false;
  @Input() public openDirectly?:boolean = false;
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
  // a function for setting the options of ng-select
  @Input() public getOptionsFn: (searchTerm:string) => any;

  @Output() public open = new EventEmitter<any>();
  @Output() public close = new EventEmitter<any>();
  @Output() public change = new EventEmitter<any>();
  @Output() public focus = new EventEmitter<any>();
  @Output() public blur = new EventEmitter<any>();
  @Output() public search = new EventEmitter<{ term:string, items:any[] }>();
  @Output() public keydown = new EventEmitter<any>();
  @Output() public clear = new EventEmitter<any>();
  @Output() public add = new EventEmitter();
  @Output() public remove = new EventEmitter();
  @Output() public scroll = new EventEmitter<{ start:number; end:number }>();
  @Output() public scrollToEnd = new EventEmitter();

  public compareByHrefOrString = AngularTrackingHelpers.compareByHrefOrString;
  public active:Set<string>;

  public searchInput$ = new Subject<string>();

  public results$ :any;

  public isLoading = false;

  @ViewChild('ngSelectInstance') ngSelectInstance: NgSelectComponent;

  @ContentChild(OpAutocompleterOptionTemplateDirective, { read: TemplateRef })
  optionTemplate:TemplateRef<any>;

  @ContentChild(OpAutocompleterLabelTemplateDirective, { read: TemplateRef })
  labelTemplate:TemplateRef<any>;

  @ContentChild(OpAutocompleterHeaderTemplateDirective, { read: TemplateRef })
  headerTemplate:TemplateRef<any>;

  constructor(
    readonly opAutocompleterService:OpAutocompleterService,
    readonly cdRef:ChangeDetectorRef,
    readonly ngZone:NgZone,
  ) {
    super();
  }

  ngAfterViewInit():void {

    if (!this.ngSelectInstance) {
      return;
    }

    this.typeToSearchText = this.typeToSearchText ? this.typeToSearchText : this.placeholder;
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.results$ = this.defaulData ? (this.searchInput$.pipe(
          debounceTime(250),
          distinctUntilChanged(),
          switchMap(queryString => this.opAutocompleterService.loadData(queryString, this.resource, this.filters, this.searchKey))
        )) : (this.searchInput$.pipe(
          debounceTime(250),
          distinctUntilChanged(),
          switchMap(queryString => this.getOptionsFn(queryString))
        ));

        this.ngSelectInstance.focus();
        this.repositionDropdown();
      }, 25);
    });

  }

  public repositionDropdown() {

    if (this.ngSelectInstance) {
      setTimeout(() => {
        this.cdRef.detectChanges();
        const component = (this.ngSelectInstance) as any;
        if (component && component.dropdownPanel) {
          component.dropdownPanel._updatePosition();
        }
      }, 25);
    }
  }

  public opened(val:any) {

   if (this.openDirectly) {
    this.results$ = this.defaulData 
    ? (this.opAutocompleterService.loadData('', this.resource, this.filters, this.searchKey))
    : (this.getOptionsFn(''));
    this.repositionDropdown();
   }
    this.open.emit();
  }
  public closeSelect() {
    this.ngSelectInstance && this.ngSelectInstance.close();
  }
  public closed(val:any) {

    this.close.emit();
  }
  public changed(val:any) {
    this.change.emit(val);
  }

  public blured(val:any) {
    this.blur.emit(val);
  }

  public focused(val:any) {

    this.ngSelectInstance.focus();
    this.focus.emit(val);
  }

  public cleared(val:any) {
    this.clear.emit(val);
  }

  public keydowned(val:any) {
    this.keydown.emit(val);
  }
  public added(val:any) {
    this.add.emit(val);
  }
  public removed(val:any) {
    this.remove.emit(val);
  }
  public scrolled(val:any) {
    this.scroll.emit(val);
  }
  public scrolledToEnd(val:any) {
    this.scrollToEnd.emit(val);
  }
  public highlighting(property:string, id:string) {
    return Highlighting.inlineClass(property, id);
  }
}