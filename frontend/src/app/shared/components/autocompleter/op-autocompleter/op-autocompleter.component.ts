/* We just forward the ng-select outputs without renaming */
/* eslint-disable @angular-eslint/no-output-native */
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ContentChild,
  EventEmitter,
  HostBinding,
  Input,
  NgZone,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import {
  DropdownPosition,
  NgSelectComponent,
} from '@ng-select/ng-select';
import {
  BehaviorSubject,
  merge,
  NEVER,
  Observable,
  of,
  Subject,
} from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  filter,
  switchMap,
  tap,
} from 'rxjs/operators';
import { GroupValueFn } from '@ng-select/ng-select/lib/ng-select.component';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { compareByHrefOrString } from 'core-app/shared/helpers/angular/tracking-functions';
import { OpAutocompleterFooterTemplateDirective } from 'core-app/shared/components/autocompleter/autocompleter-footer-template/op-autocompleter-footer-template.directive';

import { OpAutocompleterService } from './services/op-autocompleter.service';
import { OpAutocompleterHeaderTemplateDirective } from './directives/op-autocompleter-header-template.directive';
import { OpAutocompleterLabelTemplateDirective } from './directives/op-autocompleter-label-template.directive';
import { OpAutocompleterOptionTemplateDirective } from './directives/op-autocompleter-option-template.directive';

@Component({
  selector: 'op-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './op-autocompleter.component.html',
  styleUrls: ['./op-autocompleter.component.sass'],
  providers: [OpAutocompleterService],
})
// It is component that you can use whenever you need an autocompleter
// it has all inputs and outputs of ng-select
// in order to use it, you only need to pass the data type and its filters
// you also can change the value of ng-select default options by changing @inputs and @outputs
export class OpAutocompleterComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit, OnChanges {
  @HostBinding('class.op-autocompleter') className = true;

  @Input() public filters?:IAPIFilter[] = [];

  @Input() public resource:resource;

  @Input() public model?:any;

  @Input() public searchKey?:string = '';

  @Input() public defaultData?:boolean = false;

  @Input() public focusDirectly?:boolean = true;

  @Input() public fetchDataDirectly?:boolean = false;

  @Input() public labelRequired?:boolean = true;

  @Input() public name?:string;

  @Input() public required?:boolean = false;

  @Input() public disabled?:string;

  @Input() public searchable?:boolean = true;

  @Input() public clearable?:boolean = true;

  @Input() public addTag?:boolean = false;

  @Input() public id = '';

  @Input() public accesskey?:number;

  @Input() public items?:IOPAutocompleterOption[]|HalResource[];

  private items$ = new BehaviorSubject(null);

  @Input() public clearSearchOnAdd?:boolean = true;

  @Input() public classes?:string;

  @Input() public multiple?:boolean = false;

  @Input() public openDirectly?:boolean = false;

  @Input() public bindLabel?:string;

  @Input() public bindValue?:string;

  @Input() public markFirst ? = true;

  @Input() public placeholder:string = this.I18n.t('js.autocompleter.placeholder');

  @Input() public notFoundText:string = this.I18n.t('js.autocompleter.notFoundText');

  @Input() public typeToSearchText:string = this.I18n.t('js.autocompleter.typeToSearchText');

  @Input() public addTagText?:string;

  @Input() public loadingText:string = this.I18n.t('js.ajax.loading');

  @Input() public clearAllText?:string;

  @Input() public appearance?:string;

  @Input() public dropdownPosition?:DropdownPosition = 'auto';

  @Input() public appendTo?:string;

  @Input() public closeOnSelect?:boolean = true;

  @Input() public hideSelected?:boolean = false;

  @Input() public selectOnTab?:boolean = false;

  @Input() public openOnEnter?:boolean = true;

  @Input() public maxSelectedItems?:number;

  @Input() public groupBy?:string|(() => string);

  @Input() public groupValue?:GroupValueFn;

  @Input() public bufferAmount ? = 4;

  @Input() public virtualScroll?:boolean;

  @Input() public selectableGroup?:boolean = false;

  @Input() public selectableGroupAsModel?:boolean = true;

  @Input() public searchFn:(term:string, item:any) => boolean;

  @Input() public trackByFn ? = null;

  @Input() public clearOnBackspace?:boolean = true;

  @Input() public labelForId ? = null;

  @Input() public inputAttrs?:{ [key:string]:string } = {};

  @Input() public tabIndex?:number;

  @Input() public readonly?:boolean = false;

  @Input() public searchWhileComposing?:boolean = true;

  @Input() public minTermLength ? = 0;

  @Input() public editableSearchTerm?:boolean = false;

  @Input() public keyDownFn ? = ():boolean => true;

  @Input() public typeahead:BehaviorSubject<string>|null = null;

  // a function for setting the options of ng-select
  @Input() public getOptionsFn:(searchTerm:string) => Observable<unknown>;

  @Output() public open = new EventEmitter<unknown>();

  @Output() public close = new EventEmitter<unknown>();

  @Output() public change = new EventEmitter<unknown>();

  @Output() public focus = new EventEmitter<unknown>();

  @Output() public blur = new EventEmitter<unknown>();

  @Output() public search = new EventEmitter<{ term:string, items:unknown[] }>();

  @Output() public keydown = new EventEmitter<unknown>();

  @Output() public clear = new EventEmitter<unknown>();

  @Output() public add = new EventEmitter();

  @Output() public remove = new EventEmitter();

  @Output() public scroll = new EventEmitter<{ start:number; end:number }>();

  @Output() public scrollToEnd = new EventEmitter();

  public compareByHrefOrString = compareByHrefOrString;

  public active:Set<string>;

  public results$:Observable<unknown>;

  public loading$ = new Subject<boolean>();

  @ViewChild('ngSelectInstance') ngSelectInstance:NgSelectComponent;

  @ContentChild(OpAutocompleterOptionTemplateDirective, { read: TemplateRef })
  optionTemplate:TemplateRef<any>;

  @ContentChild(OpAutocompleterLabelTemplateDirective, { read: TemplateRef })
  labelTemplate:TemplateRef<any>;

  @ContentChild(OpAutocompleterHeaderTemplateDirective, { read: TemplateRef })
  headerTemplate:TemplateRef<any>;

  @ContentChild(OpAutocompleterFooterTemplateDirective, { read: TemplateRef })
  footerTemplate:TemplateRef<any>;

  constructor(
    readonly opAutocompleterService:OpAutocompleterService,
    readonly cdRef:ChangeDetectorRef,
    readonly ngZone:NgZone,
    private readonly I18n:I18nService,
  ) {
    super();
  }

  ngOnInit() {
    if (!!this.getOptionsFn || this.defaultData) {
      this.typeahead = new BehaviorSubject<string>('');
    }
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.items) {
      this.items$.next(changes.items.currentValue);
    }
  }

  ngAfterViewInit():void {
    if (!this.ngSelectInstance) {
      return;
    }

    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.results$ = merge(
          this.items$,
          this.autocompleteInputStream(),
        );

        if (this.fetchDataDirectly) {
          this.typeahead?.next('');
        }

        if (this.openDirectly) {
          this.ngSelectInstance.open();
          this.ngSelectInstance.focus();
        } else if (this.focusDirectly) {
          this.ngSelectInstance.focus();
        }
      }, 25);
    });
  }

  public repositionDropdown() {
    if (this.ngSelectInstance) {
      setTimeout(() => {
        this.cdRef.detectChanges();
        const component = (this.ngSelectInstance) as any;
        if (component && component.dropdownPanel) {
          // component.dropdownPanel._updatePosition();
        }
      }, 25);
    }
  }

  public opened(_:unknown) { // eslint-disable-line no-unused-vars
    // Re-search for empty value as search value gets removed
    this.typeahead?.next('');
    this.repositionDropdown();
    this.open.emit();
  }

  public getOptionsItems(searchKey:string):Observable<any> {
    return of((this.items as IOPAutocompleterOption[])?.filter((element) => element.name.includes(searchKey)));
  }

  public closeSelect() {
    this.ngSelectInstance && this.ngSelectInstance.close();
  }

  public openSelect() {
    this.ngSelectInstance && this.ngSelectInstance.open();
  }

  public focusSelect() {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.ngSelectInstance.focus();
      }, 25);
    });
  }

  public closed(_:unknown) { // eslint-disable-line no-unused-vars
    this.close.emit();
  }

  public changed(val:any) {
    this.change.emit(val);
  }

  public searched(val:any) {
    this.search.emit(val);
  }

  public blured(val:any) {
    this.blur.emit(val);
  }

  public focused(val:any) {
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

  private autocompleteInputStream():Observable<unknown> {
    if (!this.typeahead) {
      return NEVER;
    }

    return this.typeahead.pipe(
      filter(() => !!(this.defaultData || this.getOptionsFn)),
      distinctUntilChanged(),
      debounceTime(250),
      tap(() => this.loading$.next(true)),
      switchMap((queryString:string) => {
        if (this.defaultData) {
          return this.opAutocompleterService.loadData(queryString, this.resource, this.filters, this.searchKey);
        }

        if (this.getOptionsFn) {
          return this.getOptionsFn(queryString);
        }

        return NEVER;
      }),
      tap(
        () => this.loading$.next(false),
        () => this.loading$.next(false),
      ),
    );
  }
}
