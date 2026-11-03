//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/* We just forward the ng-select outputs without renaming */
/* eslint-disable @angular-eslint/no-output-native */
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ContentChild, ElementRef, EventEmitter, forwardRef, HostBinding, Injector, Input, OnChanges, OnInit, Output, SimpleChanges, TemplateRef, Type, ViewChild, ViewContainerRef, ViewEncapsulation, inject } from '@angular/core';
import { DropdownPosition, NgSelectComponent } from '@ng-select/ng-select';
import { BehaviorSubject, merge, NEVER, Observable, of, Subject } from 'rxjs';
import { catchError, debounceTime, distinctUntilChanged, filter, switchMap, tap } from 'rxjs/operators';

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
  AutocompleterDropdownContext,
  AutocompleterLabelContext,
  AutocompleterOptionContext,
  AutocompleterSearchContext,
  IAPIFilter,
  AutocompleterResource,
  TOpAutocompleterResource,
} from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export interface IAutocompleteItem {
  id:ID|null;
  href:string|null;
}

export interface IAutocompleterTemplateComponent {
  optionTemplate?:TemplateRef<AutocompleterOptionContext>;
  headerTemplate?:TemplateRef<AutocompleterDropdownContext>;
  labelTemplate?:TemplateRef<AutocompleterLabelContext>;
  footerTemplate?:TemplateRef<AutocompleterDropdownContext>;
  notFoundTemplate?:TemplateRef<AutocompleterSearchContext>;
  tagTemplate?:TemplateRef<AutocompleterSearchContext>;
}

type AddTagFn = (term:string) => unknown;

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
export class OpAutocompleterComponent<T = IAutocompleteItem>
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

  @Input() public filters:IAPIFilter[] = [];

  @Input() public resource?:AutocompleterResource|null;

  @Input() public model:unknown;

  @Input() public searchKey = '';

  @Input() public defaultData = false;

  @Input() public focusDirectly = true;

  @Input() public fetchDataDirectly = false;

  @Input() public deferFetchUntilOpened = false;

  @Input() public labelRequired = true;

  @Input() public name?:string;

  @Input() public inputName?:string;

  @Input() public inputValue?:ID|ID[];

  @Input() public multipleAsSeparateInputs = true;

  @Input() public inputBindValue = 'id';

  @Input() public additionalClassProperty:string|null = null;

  @Input() public hiddenFieldAction = '';

  @Input() public required = false;

  @Input() public disabled?:boolean|string;

  @Input() public searchable = true;

  @Input() public clearable = true;

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

  @Input() public items?:T[];

  private items$ = new BehaviorSubject<T[]|null>(null);

  @Input() public clearSearchOnAdd = true;

  @Input() public classes?:string|string[]|Set<string>|Record<string, boolean>;

  @Input() public multiple = false;

  @Input() public openDirectly = false;

  @Input() public bindLabel?:string;

  @Input() public bindValue?:string;

  @Input() public markFirst = true;

  @Input() public placeholder:string = this.I18n.t('js.autocompleter.placeholder');
  @Input() public notFoundText:string = this.I18n.t('js.autocompleter.notFoundText');
  @Input() public addTagText:string = this.I18n.t('js.autocomplete_ng_select.add_tag');
  @Input() public ariaLabel:string = this.I18n.t('js.autocompleter.search');

  @Input() public loadingText:string = this.I18n.t('js.ajax.loading');

  @Input() public clearAllText?:string;

  @Input() public appearance?:string;

  @Input() public dropdownPosition:DropdownPosition = 'auto';

  @Input() public appendTo = 'body';

  @Input() public closeOnSelect = true;

  @Input() public hideSelected = false;

  @Input() public selectOnTab = false;

  @Input() public openOnEnter = true;

  @Input() public maxSelectedItems?:number;

  @Input() public groupBy?:string|((item:T|HalResource) => unknown);

  @Input() public bufferAmount = 4;

  @Input() public virtualScroll = true;

  @Input() public selectableGroup = false;

  @Input() public selectableGroupAsModel = true;

  @Input() public searchFn:(term:string, item:unknown) => boolean;

  @Input() public trackByFn = this.defaultTrackByFunction();

  @Input() public compareWith = this.defaultCompareWithFunction();

  @Input() public clearOnBackspace = true;

  @Input() public labelForId?:string;

  @Input() public inputAttrs:Record<string, string> = {};

  @Input() public tabIndex?:number;

  @Input() public readonly = false;

  @Input() public searchWhileComposing = true;

  @Input() public minTermLength = 0;

  @Input() public editableSearchTerm = false;

  @Input() public keyDownFn = (_event:KeyboardEvent):boolean => true;

  @Input() public typeahead:BehaviorSubject<string>|null = null;

  protected readonly localSearch = new Subject<string>();

  @Input() public resetOnChange = false;

  // a function for setting the options of ng-select
  @Input() public getOptionsFn:(searchTerm:string) => Observable<T[]>;

  @Input() public url:string;

  @Input() public debounceTimeMs = 250;

  @Output() public open = new EventEmitter<void>();

  @Output() public close = new EventEmitter<void>();

  @Output() public cancel = new EventEmitter<Event|undefined>();

  @Output() public change = new EventEmitter<unknown>();

  @Output() public focus = new EventEmitter<FocusEvent>();

  @Output() public blur = new EventEmitter<FocusEvent>();

  @Output() public search = new EventEmitter<{ term:string, items:unknown[] }>();

  @Output() public keydown = new EventEmitter<KeyboardEvent>();

  @Output() public clear = new EventEmitter<void>();

  @Output() public add = new EventEmitter<unknown>();

  @Output() public remove = new EventEmitter<unknown>();

  @Output() public scroll = new EventEmitter<{ start:number; end:number }>();

  @Output() public scrollToEnd = new EventEmitter<void>();

  public active:Set<string>;

  public results$:Observable<(T|HalResource)[]|null>;

  public loading$ = new Subject<boolean>();

  private hasBeenOpened = false;

  @ViewChild('ngSelectInstance') ngSelectInstance:NgSelectComponent;

  @ViewChild('syncedInput') syncedInput:ElementRef<HTMLInputElement>;

  // Exposed so other autocompleter consumers (e.g. global search) can render
  // work package results with the exact same markup/styling.
  @ViewChild('workPackageOption') public workPackageOption:TemplateRef<AutocompleterOptionContext>;

  @ContentChild(OpAutocompleterOptionTemplateDirective, { read: TemplateRef })
  projectedOptionTemplate:TemplateRef<AutocompleterOptionContext>;

  optionTemplate:TemplateRef<AutocompleterOptionContext>;

  @ContentChild(OpAutocompleterLabelTemplateDirective, { read: TemplateRef })
  projectedLabelTemplate:TemplateRef<AutocompleterLabelContext>;

  labelTemplate:TemplateRef<AutocompleterLabelContext>;

  @ContentChild(OpAutocompleterHeaderTemplateDirective, { read: TemplateRef })
  projectedHeaderTemplate:TemplateRef<AutocompleterDropdownContext>;

  headerTemplate:TemplateRef<AutocompleterDropdownContext>;

  @ContentChild(OpAutocompleterFooterTemplateDirective, { read: TemplateRef })
  projectedFooterTemplate:TemplateRef<AutocompleterDropdownContext>;

  footerTemplate:TemplateRef<AutocompleterDropdownContext>;

  notFoundTemplate:TemplateRef<AutocompleterSearchContext>;

  tagTemplate:TemplateRef<AutocompleterSearchContext>;

  readonly opAutocompleterService = inject(OpAutocompleterService);

  ngOnInit() {
    populateInputsFromDataset(this);

    if (!!this.getOptionsFn || this.defaultData) {
      this.typeahead = new BehaviorSubject<string>('');
    }

    if (this.items) {
      this.items$.next(this.items);
    }
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.items) {
      this.items$.next(this.items ?? null);
    }
  }

  ngAfterViewInit():void {
    // Store ng-select instance on the host element for access from Stimulus controllers
    this.elementRef.nativeElement.ngSelectComponentInstance = this.ngSelectInstance;

    if (this.inputName && this.model) {
      this.syncHiddenField(this.mappedInputValue);
    }

    if (this.inputValue && this.isApiResource(this.resource) && !this.model) {
      this
        .opAutocompleterService
        .loadValue(this.inputValue, this.resource, this.multiple)
        .subscribe((resource) => {
          this.model = resource;
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
    if (Array.isArray(this.model)) {
      const values = this.model.map(value => this.inputValueFor(value));
      return values.length > 0 ? values : [''];
    }

    return this.inputValueFor(this.model);
  }

  private inputValueFor(value:unknown):string {
    const boundValue = typeof value === 'object' && value !== null
      ? (value as Record<string, unknown>)[this.inputBindValue]
      : value;
    return typeof boundValue === 'string' || typeof boundValue === 'number' ? String(boundValue) : '';
  }

  protected isApiResource(resource:AutocompleterResource|null|undefined):resource is TOpAutocompleterResource {
    return resource === 'work_packages' || resource === 'users' || resource === 'principals'
      || resource === 'projects' || resource === 'portfolios' || resource === 'programs';
  }

  public repositionDropdown() {
    repositionDropdownBugfix(this.ngSelectInstance);
  }

  public opened():void {
    if (this.deferFetchUntilOpened && !this.hasBeenOpened) {
      this.hasBeenOpened = true;
      this.typeahead?.next(this.ngSelectInstance.searchTerm ?? '');
    }

    this.repositionDropdown();
    this.open.emit();
  }

  public getOptionsItems(searchKey:string):Observable<T[]|undefined> {
    return of(this.items?.filter((element) => {
      const name:unknown = typeof element === 'object' && element !== null && 'name' in element ? element.name : undefined;
      return typeof name === 'string' && name.includes(searchKey);
    }));
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

  public changed(val:unknown):void {
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

  public blured(val:FocusEvent):void {
    this.blur.emit(val);
  }

  public focused(val:FocusEvent):void {
    this.focus.emit(val);
  }

  public cleared():void {
    this.clear.emit();
  }

  public keydowned(val:KeyboardEvent):void {
    this.keydown.emit(val);
  }

  public added(val:unknown):void {
    this.add.emit(val);
  }

  public canceled(val:Event):void {
    this.cancel.emit(val);
  }

  public removed(val:unknown):void {
    this.remove.emit(val);
  }

  public scrolled(val:{ start:number; end:number }):void {
    this.scroll.emit(val);
  }

  public scrolledToEnd():void {
    this.scrollToEnd.emit();
  }

  public highlighting(property:string, id:string):string {
    return Highlighting.inlineClass(property, id);
  }

  private autocompleteInputStream():Observable<(T|HalResource)[]> {
    if (!this.typeahead) {
      return NEVER;
    }

    return this.typeahead.pipe(
      filter(() => [this.defaultData, this.url, this.getOptionsFn].some(Boolean)),
      // Must precede distinctUntilChanged, which would otherwise dedupe the term
      // replayed by opened() against the suppressed initial one.
      filter(() => !this.deferFetchUntilOpened || this.hasBeenOpened),
      distinctUntilChanged(),
      tap(() => this.loading$.next(true)),
      debounceTime(this.debounceTimeForCurrentEnvironment),
      switchMap((queryString:string) => {
        let source$:Observable<(T|HalResource)[]> = of([]);

        if (this.getOptionsFn) {
          source$ = this.getOptionsFn(queryString);
        } else if (this.url) {
          source$ = this.opAutocompleterService.loadFromUrl(this.url, queryString, this.resource, this.filters, this.searchKey);
        } else if (this.defaultData && this.isApiResource(this.resource)) {
          source$ = this.opAutocompleterService.loadData(queryString, this.resource, this.filters, this.searchKey);
        }

        return source$.pipe(
          catchError((error) => {
            console.error(error);
            return of([]);
          }),
        );
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

  writeValue(value:unknown):void {
    this.model = value;
  }

  onChange = (_:unknown):void => undefined;

  onTouched = (_:unknown):void => undefined;

  registerOnChange(fn:(_:unknown) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:unknown) => void):void {
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

    const applyTemplate = <K extends keyof IAutocompleterTemplateComponent>(target:IAutocompleterTemplateComponent, name:K) => {
      const template = componentRef.instance[name];
      if (template) {
        target[name] = template;
      }
    };
    applyTemplate(this, 'optionTemplate');
    applyTemplate(this, 'headerTemplate');
    applyTemplate(this, 'labelTemplate');
    applyTemplate(this, 'footerTemplate');
    applyTemplate(this, 'notFoundTemplate');
    applyTemplate(this, 'tagTemplate');
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

  protected defaultTrackByFunction():((item:unknown) => unknown)|null {
    return null;
  }

  protected defaultCompareWithFunction():(a:unknown, b:unknown) => boolean {
    return (a, b) => {
      if (this.bindValue && !(typeof b === 'object' && b !== null)) {
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
