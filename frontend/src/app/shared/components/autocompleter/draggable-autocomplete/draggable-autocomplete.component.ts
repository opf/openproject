import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnInit,
  OnDestroy,
  Output,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { DragulaService, Group } from 'ng2-dragula';
import { DomAutoscrollService } from 'core-app/shared/helpers/drag-and-drop/dom-autoscroll.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { setBodyCursor } from 'core-app/shared/helpers/dom/set-window-cursor.helper';
import {
  repositionDropdownBugfix,
} from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { AlternativeSearchService } from 'core-app/shared/components/work-packages/alternative-search.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { merge } from 'rxjs';

export interface DraggableOption {
  name:string;
  id:string;
}

@Component({
  selector: 'op-draggable-autocompleter',
  templateUrl: './draggable-autocomplete.component.html',
  styleUrls: ['./draggable-autocomplete.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DraggableAutocompleteComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit, OnDestroy {
  /** Options to show in the autocompleter */
  @Input() options:DraggableOption[];

  /** Order list of selected items */
  @Input() selected:DraggableOption[] = [];

  /** List of options that are protected from being deleted. They can still be moved. */
  @Input() protected:DraggableOption[] = [];

  /** Should we focus the autocompleter ? */
  @Input() autofocus = true;

  @Input() name = '';

  /** Id of the autocompleter input */
  @Input() id = this.name;

  /** Label to display above the autocompleter */
  @Input() inputLabel = '';

  /** Placeholder text to display in the autocompleter input */
  @Input() inputPlaceholder = '';

  /** Label to display below the autocompleter input */
  @Input() inputCaption = '';

  /** Label to display drag&drop area */
  @Input() dragAreaLabel = '';

  /** Name of drag&drop area group */
  @Input() dragAreaName = 'columns';

  /** Decide whether to bind the component to the component or to the body */
  /** Binding to the component in case the component is inside a Primer Dialog which uses popover */
  @Input() appendToComponent = false;
  @Input() formControlId = 'op-draggable-autocomplete-container';

  /** Output when autocompleter changes values or items removed */
  @Output() onChange = new EventEmitter<DraggableOption[]>();

  /** List of items still available for selection */
  availableOptions:DraggableOption[] = [];

  private autoscroll:any;

  private columnsGroup:Group;

  @ViewChild('ngSelectComponent') public ngSelectComponent:NgSelectComponent;
  @ViewChild('input') inputElement:ElementRef;

  public appendTo = 'body';

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly dragula:DragulaService,
    readonly alternativeSearchService:AlternativeSearchService,
  ) {
    super();
  }

  ngOnInit():void {
    populateInputsFromDataset(this);

    this.dragula.destroy(this.dragAreaName);

    this.updateAvailableOptions();

    // Setup groups
    this.columnsGroup = this.dragula.createGroup(
      this.dragAreaName,
      { mirrorContainer: this.appendToComponent ? document.getElementById(this.formControlId)! : document.body },
    );

    // Set cursor when dragging
    this.dragula.drag(this.dragAreaName)
      .pipe(this.untilDestroyed())
      .subscribe(() => setBodyCursor('move', 'important'));

    // Reset cursor when cancel or dropped
    merge(
      this.dragula.drop(this.dragAreaName),
      this.dragula.cancel(this.dragAreaName),
    )
      .pipe(this.untilDestroyed())
      .subscribe(() => setBodyCursor('auto'));

    // Setup autoscroll
    const that = this;
    this.autoscroll = new DomAutoscrollService(
      [
        document.getElementById('content-body')!,
      ],
      {
        margin: 25,
        maxSpeed: 10,
        scrollWhenOutside: true,
        autoScroll(this:any) {
          return this.down && that.columnsGroup.drake.dragging;
        },
      },
    );

    this.appendTo = this.appendToComponent ? `#${this.formControlId}` : 'body';
  }

  ngAfterViewInit():void {
    if (this.autofocus) {
      this.ngSelectComponent.focus();
    }

    // Set the id of the input so that it matches the label.
    const input = this.ngSelectComponent.element.querySelector('input');
    if (input) {
      input.id = this.id;
    }
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    this.dragula.destroy(this.dragAreaName);
  }

  select(item:DraggableOption|undefined) {
    if (!item) {
      return;
    }

    this.selectedOptions = [...this.selectedOptions, item];

    // Remove selection
    this.ngSelectComponent.clearModel();
  }

  remove(item:DraggableOption) {
    this.selectedOptions = this.selectedOptions.filter((selected) => selected.id !== item.id);
  }

  isRemovable(item:DraggableOption) {
    return !this.protected.find((protectedItem) => protectedItem.id === item.id);
  }

  get selectedOptions() {
    return this.selected;
  }

  set selectedOptions(val:DraggableOption[]) {
    this.selected = val;
    this.updateAvailableOptions();

    this.onChange.emit(this.selectedOptions);
  }

  get hiddenValue() {
    return this.selectedOptions.map((item) => item.id).join(' ');
  }

  get hiddenValues() {
    return this.selectedOptions.map((item) => item.id);
  }

  get isArrayOfValues() {
    return this.name.endsWith('[]');
  }

  opened() {
    repositionDropdownBugfix(this.ngSelectComponent);
  }

  searchFunction = (term:string, currentItem:QueryFilterResource):boolean => {
    return this.alternativeSearchService.searchFunction(term, currentItem);
  };

  private updateAvailableOptions() {
    this.availableOptions = this.options
      .filter((item) => !this.selectedOptions.find((selected) => selected.id === item.id));
  }
}
