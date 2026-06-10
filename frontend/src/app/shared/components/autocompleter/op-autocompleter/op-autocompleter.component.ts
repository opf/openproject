/* We just forward the ng-select outputs without renaming */
/* eslint-disable @angular-eslint/no-output-native */
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ContentChild, ElementRef, EventEmitter, forwardRef, HostBinding, Injector, Input, OnChanges, OnInit, Output, SimpleChanges, TemplateRef, Type, ViewChild, ViewContainerRef, ViewEncapsulation, inject } from '@angular/core';
import { DropdownPosition, NgSelectComponent } from '@ng-select/ng-select';
import { BehaviorSubject, merge, NEVER, Observable, of, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, filter, switchMap, tap } from 'rxjs/operators';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  OpAutocompleterFooterTemplateDirective,
} from 'core-app/shared/components/autocompleter/autocompleter-footer-template/op-autocompleter-footer-template.directive';

import { OpAutocompleterService } from './services/op-autocompleter.service';
import { OpAutocompleterHeaderTemplateDirective } from './directives/op-autocompleter-header-template.directive';
import { OpAutocompleterLabelTemplateDirective } from './directives/op-autocompleter-label-template.directive';
import { OpAutocompleterOptionTemplateDirective } from './directives/op-autocompleter-option-template.directive';
import {
  repositionDropdownBugfix,
} from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { ID } from '@datorama/akita';
import { HttpClient } from '@angular/common/http';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import {
  IAPIFilter,
  IOPAutocompleterOption,
  TOpAutocompleterResource,
} from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export interface IAutocompleteItem {
  id:ID;
  href:string|null;
}

export interface IAutocompleterTemplateComponent {
  optionTemplate?:TemplateRef<Element>;
  headerTemplate?:TemplateRef<Element>;
  labelTemplate?:TemplateRef<Element>;
  footerTemplate?:TemplateRef<Element>;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-redundant-type-constituents
type AddTagFn = (term:string) => any | Promise<any>;
// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-redundant-type-constituents
type GroupValueFn = (key:string | any, children:any[]) => string | any;

@Component({
  selector: 'op-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  templateUrl: './op-autocompleter.component.html',
  styleUrls: ['./op-autocompleter.component.sass'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpAutocompleterComponent),
      multi: true,
    },
  ],
  standalone: false,
})
// It is component that you can use whenever you need an autocompleter
// it has all inputs and outputs of ng-select
// in order to use it, you only need to pass the data type and its filters
// you also can change the value of ng-select default options by changing @inputs and @outputs
export class OpAutocompleterComponent<T extends IAutocompleteItem = IAutocompleteItem>
  extends UntilDestroyedMixin
  implements OnInit, AfterViewInit, OnChanges, ControlValueAccessor {
  readonly injector = inject(Injector);
  readonly elementRef = inject<ElementRef<HTMLElement & { ngSelectComponentInstance?:NgSelectComponent }>>(ElementRef);
  readonly http = inject(HttpClient);
  readonly apiV3Service = inject(ApiV3Service);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly vcRef = inject(ViewContainerRef);
  readonly I18n = inject(I18nService);
  readonly halResourceService = inject(HalResourceService);
  readonly pathHelperService = inject(PathHelperService);

  @HostBinding('class.op-autocompleter') className = true;

  @Input() public filters?:IAPIFilter[] = [];

  @Input() public resource:TOpAutocompleterResource;

  @Input() public model?:T|T[]|null;

  @Input() public searchKey?:string = '';

  @Input() public defaultData?:boolean = false;

  @Input() public focusDirectly?:boolean = true;

  @Input() public fetchDataDirectly?:boolean = false;

  @Input() public labelRequired?:boolean = true;

  @Input() public name?:string;

  @Input() public inputName?:string;

  @Input() public inputValue?:string|string[];

  @Input() public multipleAsSeparateInputs = true;

  @Input() public inputBindValue = 'id';

  @Input() public additionalClassProperty:string|null = null;

  @Input() public hiddenFieldAction = '';

  @Input() public required?:boolean = false;

  @Input() public disabled?:string;

  @Input() public searchable?:boolean = true;

  @Input() public clearable?:boolean = true;

  @Input() set addTag(val:boolean|AddTagFn) {
    this._addTag = val === true ? this.addNewObjectFn.bind(this) : val;
    this.cdRef.detectChanges();
  }

  get addTag():boolean|AddTagFn {
    return this._addTag;
  }

  private _addTag:boolean|AddTagFn = false;

  @Input() public id = '';

  @Input() public accesskey?:number;

  @Input() public items?:IOPAutocompleterOption[]|HalResource[];

  private items$ = new BehaviorSubject<IOPAutocompleterOption[]|null>(null);

  @Input() public clearSearchOnAdd?:boolean = true;

  @Input() public classes?:string;

  @Input() public multiple = false;

  @Input() public openDirectly?:boolean = false;

  @Input() public bindLabel?:string;

  @Input() public bindValue?:string;

  @Input() public markFirst ? = true;

  @Input() public placeholder:string = this.I18n.t('js.autocompleter.placeholder');
  @Input() public notFoundText:string = this.I18n.t('js.autocompleter.notFoundText');
  @Input() public addTagText?:string = this.I18n.t('js.autocomplete_ng_select.add_tag');
  @Input() public ariaLabel?:string = this.I18n.t('js.autocompleter.search');

  @Input() public loadingText:string = this.I18n.t('js.ajax.loading');

  @Input() public clearAllText?:string;

  @Input() public appearance?:string;

  @Input() public dropdownPosition?:DropdownPosition = 'auto';

  @Input() public appendTo = 'body';

  @Input() public closeOnSelect?:boolean = true;

  @Input() public hideSelected?:boolean = false;

  @Input() public selectOnTab?:boolean = false;

  @Input() public openOnEnter?:boolean = true;

  @Input() public maxSelectedItems?:number;

  @Input() public groupBy?:string|(() => string);

  @Input() public groupValue?:GroupValueFn;

  @Input() public bufferAmount ? = 4;

  @Input() public virtualScroll = true;

  @Input() public selectableGroup?:boolean = false;

  @Input() public selectableGroupAsModel?:boolean = true;

  @Input() public searchFn:(term:string, item:unknown) => boolean;

  @Input() public trackByFn = this.defaultTrackByFunction();

  @Input() public compareWith = this.defaultCompareWithFunction();

  @Input() public clearOnBackspace?:boolean = true;

  @Input() public labelForId?:string;

  @Input() public inputAttrs?:Record<string, string> = {};

  @Input() public tabIndex?:number;

  @Input() public readonly?:boolean = false;

  @Input() public searchWhileComposing?:boolean = true;

  @Input() public minTermLength ? = 0;

  @Input() public editableSearchTerm?:boolean = false;

  @Input() public keyDownFn ? = ():boolean => true;

  @Input() public typeahead:BehaviorSubject<string>|null = null;

  @Input() public resetOnChange?:boolean = false;

  // a function for setting the options of ng-select
  @Input() public getOptionsFn:(searchTerm:string) => Observable<unknown>;

  @Input() public url:string;

  @Input() public debounceTimeMs = 250;

  @Output() public open = new EventEmitter<unknown>();

  @Output() public close = new EventEmitter<unknown>();

  @Output() public cancel = new EventEmitter<unknown>();

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

  public active:Set<string>;

  public results$:Observable<unknown>;

  public loading$ = new Subject<boolean>();

  @ViewChild('ngSelectInstance') ngSelectInstance:NgSelectComponent;

  @ViewChild('syncedInput') syncedInput:ElementRef<HTMLInputElement>;

  @ContentChild(OpAutocompleterOptionTemplateDirective, { read: TemplateRef })
  projectedOptionTemplate:TemplateRef<Element>;

  optionTemplate:TemplateRef<Element>;

  @ContentChild(OpAutocompleterLabelTemplateDirective, { read: TemplateRef })
  projectedLabelTemplate:TemplateRef<Element>;

  labelTemplate:TemplateRef<Element>;

  @ContentChild(OpAutocompleterHeaderTemplateDirective, { read: TemplateRef })
  projectedHeaderTemplate:TemplateRef<Element>;

  headerTemplate:TemplateRef<Element>;

  @ContentChild(OpAutocompleterFooterTemplateDirective, { read: TemplateRef })
  projectedFooterTemplate:TemplateRef<Element>;

  footerTemplate:TemplateRef<Element>;

  readonly opAutocompleterService = inject(OpAutocompleterService);

  ngOnInit() {
    populateInputsFromDataset(this);

    if (!!this.getOptionsFn || this.defaultData) {
      this.typeahead = new BehaviorSubject<string>('');
    }

    if (this.items) {
      this.items$.next(this.items as IOPAutocompleterOption[]);
    }
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.items) {
      this.items$.next(changes.items.currentValue as IOPAutocompleterOption[]);
    }
  }

  ngAfterViewInit():void {
    // Store ng-select instance on the host element for access from Stimulus controllers
    this.elementRef.nativeElement.ngSelectComponentInstance = this.ngSelectInstance;

    if (this.inputName && this.model) {
      this.syncHiddenField(this.mappedInputValue);
    }

    if (this.inputValue && this.resource && !this.model) {
      this
        .opAutocompleterService
        .loadValue(this.inputValue, this.resource, this.multiple)
        .subscribe((resource) => {
          this.model = resource as unknown as T;
          this.syncHiddenField(this.mappedInputValue);
          this.cdRef.detectChanges();
        });
    }

    setTimeout(() => {
      this.results$ = merge(
        this.items$,
        this.autocompleteInputStream(),
      );

      if (this.fetchDataDirectly) {
        this.typeahead?.next('');
      }

      if (this.openDirectly) {
        // Autocompleters within dialogs need longer to be visible, which is why we have to delay the opening further
        const timeout = this.ngSelectInstance.element.closest('dialog') ? 200 : 0;
        setTimeout(() => {
          this.ngSelectInstance.open();
          this.ngSelectInstance.focus();
        }, timeout);
      } else if (this.focusDirectly) {
        this.ngSelectInstance.focus();
      }

      this.cdRef.detectChanges();
    }, 25);
  }

  public get mappedInputValue():string|string[] {
    if (!this.model) {
      return '';
    } else if (Array.isArray(this.model)) {
      const mappedValues = this.model.map((el) => (_.isObject(el) ? el[this.inputBindValue as 'id'] : el) as string);
      return mappedValues.length > 0 ? mappedValues : [''];
    } else {
      return this.model[this.inputBindValue as 'id'] as string || '';
    }
  }

  public repositionDropdown() {
    repositionDropdownBugfix(this.ngSelectInstance);
  }

  public opened():void {
    this.repositionDropdown();
    this.open.emit();
  }

  public getOptionsItems(searchKey:string):Observable<unknown> {
    return of((this.items as IOPAutocompleterOption[])?.filter((element) => element.name.includes(searchKey)));
  }

  public closeSelect():void {
    this.ngSelectInstance?.close();
  }

  public openSelect():void {
    this.ngSelectInstance?.open();
  }

  public focusSelect():void {
    setTimeout(() => {
      this.ngSelectInstance.focus();
    }, 25);
  }

  public closed():void {
    this.close.emit();
  }

  public changed(val:T|T[]|null):void {
    this.writeValue(val);
    this.onTouched(val);
    this.onChange(val);
    this.syncHiddenField(this.mappedInputValue);
    this.syncedInput?.nativeElement.dispatchEvent(new Event('change'));
    this.change.emit(val);

    if (this.resetOnChange) {
      this.ngSelectInstance.clearModel();
    }

    this.cdRef.detectChanges();
  }

  public searched(val:{ term:string, items:unknown[] }):void {
    this.search.emit(val);
  }

  public blured(val:unknown):void {
    this.blur.emit(val);
  }

  public focused(val:unknown):void {
    this.focus.emit(val);
  }

  public cleared(val:unknown):void {
    this.clear.emit(val);
  }

  public keydowned(val:unknown):void {
    this.keydown.emit(val);
  }

  public added(val:unknown):void {
    this.add.emit(val);
  }

  public canceled(val:unknown):void {
    this.cancel.emit(val);
  }

  public removed(val:unknown):void {
    this.remove.emit(val);
  }

  public scrolled(val:{ start:number; end:number }):void {
    this.scroll.emit(val);
  }

  public scrolledToEnd(val:unknown):void {
    this.scrollToEnd.emit(val);
  }

  public highlighting(property:string, id:string):string {
    return Highlighting.inlineClass(property, id);
  }

  private autocompleteInputStream():Observable<unknown> {
    if (!this.typeahead) {
      return NEVER;
    }

    return this.typeahead.pipe(
      filter(() => [this.defaultData, this.url, this.getOptionsFn].some(Boolean)),
      distinctUntilChanged(),
      tap(() => this.loading$.next(true)),
      debounceTime(this.debounceTimeForCurrentEnvironment),
      switchMap((queryString:string) => {
        if (this.getOptionsFn) {
          return this.getOptionsFn(queryString);
        }

        if (this.url) {
          return this.opAutocompleterService.loadFromUrl(this.url, queryString, this.resource, this.filters, this.searchKey);
        }

        if (this.defaultData) {
          return this.opAutocompleterService.loadData(queryString, this.resource, this.filters, this.searchKey);
        }

        return NEVER;
      }),
      tap({
        next: () => this.loading$.next(false),
        error: () => this.loading$.next(false),
      }),
    );
  }

  private get debounceTimeForCurrentEnvironment():number {
    return (window.OpenProject?.environment === 'test') ? 0 : this.debounceTimeMs;
  }

  writeValue(value:T|T[]|null):void {
    this.model = value;
  }

  onChange = (_:T|T[]|null):void => undefined;

  onTouched = (_:T|T[]|null):void => undefined;

  registerOnChange(fn:(_:T|T[]|null) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:T|T[]|null) => void):void {
    this.onTouched = fn;
  }

  /**
   * Instantiate the given template component and apply any given TemplateRef to this component
   * so they can be passed to ng-select.
   *
   * @param component A templating component defining any combination of the header, option, label, or footer templates.
   * @param inputs Initial inputs to the templating component
   * @protected
   */
  protected applyTemplates(component:Type<IAutocompleterTemplateComponent>, inputs:Record<string, unknown> = {}) {
    const componentRef = this.vcRef.createComponent(component, { injector: this.templateInjector });
    Object.keys(inputs).forEach((key) => {
      const value = inputs[key];
      componentRef.setInput(key, value);
    });

    componentRef.changeDetectorRef.detectChanges();

    ['optionTemplate', 'headerTemplate', 'labelTemplate', 'footerTemplate'].forEach((name:keyof IAutocompleterTemplateComponent) => {
      const template = componentRef.instance[name];
      if (template) {
        this[name] = template;
      }
    });
  }

  protected get templateInjector() {
    return Injector.create(
      {
        providers: [{ provide: OpAutocompleterComponent, useValue: this }],
        parent: this.injector,
      },
    );
  }

  protected syncHiddenField(mappedInputValue:string|string[]):void {
    const input = this.syncedInput?.nativeElement;
    if (!input) {
      return;
    }

    const newValue = Array.isArray(mappedInputValue) ? mappedInputValue.join(',') : mappedInputValue;
    // Don't fire a change event if the value is the same
    if (input.value === newValue) {
      return;
    }

    input.value = newValue;
  }

  public addNewObjectFn(searchTerm:string):unknown {
    return this.bindLabel ? { [this.bindLabel]: searchTerm } : searchTerm;
  }

  protected defaultTrackByFunction():((x:unknown) => unknown)|null {
    return null;
  }

  protected defaultCompareWithFunction():null|((a:unknown, b:unknown) => boolean) {
    return (a, b) => {
      if (this.bindValue && !_.isObject(b)) {
        return (a as Record<string, unknown>)[this.bindValue] === b;
      }

      return a === b;
    };
  }

  /**
   * Attaches hover card event listeners by setting this attribute for users.
   */
  protected getHoverCardTriggerTarget(item:HalResource) {
    return item instanceof UserResource ? 'trigger' : '';
  }

  /**
   * Enables hover card data loading by setting this attribute for users.
   */
  protected getHoverCardUrl(item:HalResource) {
    if (item instanceof UserResource && item.id) {
      return this.pathHelperService.userHoverCardPath(item.id);
    }

    return '';
  }
}
