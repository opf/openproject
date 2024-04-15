/* We just forward the ng-select outputs without renaming */
/* eslint-disable @angular-eslint/no-output-native */
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ContentChild,
  ElementRef,
  EventEmitter,
  forwardRef,
  HostBinding,
  Injector,
  Input,
  NgZone,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
  TemplateRef,
  Type,
  ViewChild,
  ViewContainerRef,
} from '@angular/core';
import { DropdownPosition, NgSelectComponent } from '@ng-select/ng-select';
import { BehaviorSubject, merge, NEVER, Observable, of, Subject, timer } from 'rxjs';
import { debounce, distinctUntilChanged, filter, switchMap, tap } from 'rxjs/operators';
import { AddTagFn, GroupValueFn } from '@ng-select/ng-select/lib/ng-select.component';

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

@Component({
  selector: 'op-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './op-autocompleter.component.html',
  styleUrls: ['./op-autocompleter.component.sass'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpAutocompleterComponent),
      multi: true,
    },
  ],
})
// It is component that you can use whenever you need an autocompleter
// it has all inputs and outputs of ng-select
// in order to use it, you only need to pass the data type and its filters
// you also can change the value of ng-select default options by changing @inputs and @outputs
export class OpAutocompleterComponent<T extends IAutocompleteItem = IAutocompleteItem>
  extends UntilDestroyedMixin
  implements OnInit, AfterViewInit, OnChanges, ControlValueAccessor {
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

  private items$ = new BehaviorSubject(null);

  @Input() public clearSearchOnAdd?:boolean = true;

  @Input() public classes?:string;

  @Input() public multiple = false;

  @Input() public openDirectly?:boolean = false;

  @Input() public bindLabel?:string;

  @Input() public bindValue?:string;

  @Input() public markFirst ? = true;

  @Input() public placeholder:string = this.I18n.t('js.autocompleter.placeholder');
  @Input() public notFoundText:string = this.I18n.t('js.autocompleter.notFoundText');
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

  @Input() public virtualScroll = true;

  @Input() public selectableGroup?:boolean = false;

  @Input() public selectableGroupAsModel?:boolean = true;

  @Input() public searchFn:(term:string, item:any) => boolean;

  @Input() public trackByFn = this.defaultTrackByFunction();

  @Input() public compareWith = this.defaultCompareWithFunction();

  @Input() public clearOnBackspace?:boolean = true;

  @Input() public labelForId?:string;

  @Input() public inputAttrs?:{ [key:string]:string } = {};

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

  initialDebounce = true;

  private opAutocompleterService = new OpAutocompleterService(this.apiV3Service);

  constructor(
    readonly injector:Injector,
    readonly elementRef:ElementRef,
    readonly http:HttpClient,
    readonly apiV3Service:ApiV3Service,
    readonly cdRef:ChangeDetectorRef,
    readonly ngZone:NgZone,
    readonly vcRef:ViewContainerRef,
    readonly I18n:I18nService,
  ) {
    super();
  }

  ngOnInit() {
    populateInputsFromDataset(this);

    if (!!this.getOptionsFn || this.defaultData) {
      this.typeahead = new BehaviorSubject<string>('');
    }

    if (this.inputValue && !this.model) {
      this
        .opAutocompleterService
        .loadValue(this.inputValue, this.resource, this.multiple)
        .subscribe((resource) => {
          this.model = resource as unknown as T;
          this.syncHiddenField(this.mappedInputValue);
          this.cdRef.detectChanges();
        });
    }
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.items) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      this.items$.next(changes.items.currentValue);
    }
  }

  ngAfterViewInit():void {
    if (this.inputName && this.model) {
      this.syncHiddenField(this.mappedInputValue);
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

  public get mappedInputValue():string|string[] {
    if (!this.model) {
      return '';
    }

    if (Array.isArray(this.model)) {
      return this.model.map((el) => el[this.inputBindValue as 'id'] as string);
    }

    return this.model[this.inputBindValue as 'id'] as string;
  }

  public repositionDropdown() {
    repositionDropdownBugfix(this.ngSelectInstance);
  }

  public opened():void { // eslint-disable-line no-unused-vars
    this.repositionDropdown();
    this.open.emit();
  }

  public getOptionsItems(searchKey:string):Observable<any> {
    return of((this.items as IOPAutocompleterOption[])?.filter((element) => element.name.includes(searchKey)));
  }

  public closeSelect():void {
    this.ngSelectInstance?.close();
  }

  public openSelect():void {
    this.ngSelectInstance?.open();
  }

  public focusSelect():void {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.ngSelectInstance.focus();
      }, 25);
    });
  }

  public closed():void {
    this.close.emit();
  }

  public changed(val:T|T[]|null):void {
    this.writeValue(val);
    this.onTouched(val);
    this.onChange(val);
    this.syncHiddenField(this.mappedInputValue);
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
      filter(() => !!(this.defaultData || this.getOptionsFn)),
      distinctUntilChanged(),
      tap(() => this.loading$.next(true)),
      // tap(() => console.log('Debounce is ', this.getDebounceTimeout())),
      debounce(() => timer(this.getDebounceTimeout())),
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

  private getDebounceTimeout():number {
    if (this.initialDebounce) {
      this.initialDebounce = false;
      return 0;
    }
    return 50;
  }

  writeValue(value:T|T[]|null):void {
    this.model = value;
  }

  onChange = (_:T|T[]|null):void => {
  };

  onTouched = (_:T|T[]|null):void => {
  };

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
  protected applyTemplates(component:Type<IAutocompleterTemplateComponent>, inputs:{ [key:string]:unknown } = {}) {
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

  protected syncHiddenField(mappedInputValue:string|string[]) {
    const input = this.syncedInput?.nativeElement;
    if (input) {
      input.value = Array.isArray(mappedInputValue) ? mappedInputValue.join(',') : mappedInputValue;
      const event = new Event('change');
      input.dispatchEvent(event);
    }
  }

  public addNewObjectFn(searchTerm:string):unknown {
    return this.bindLabel ? { [this.bindLabel]: searchTerm } : searchTerm;
  }

  protected defaultTrackByFunction():((x:unknown) => unknown)|null {
    return null;
  }

  protected defaultCompareWithFunction():(a:unknown, b:unknown) => boolean {
    return (a, b) => a === b;
  }
}
