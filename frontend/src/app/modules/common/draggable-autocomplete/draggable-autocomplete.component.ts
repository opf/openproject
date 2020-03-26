import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild
} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {DragulaService, Group} from "ng2-dragula";
import {DomAutoscrollService} from "core-app/modules/common/drag-and-drop/dom-autoscroll.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {merge} from "rxjs";
import {DomHelpers} from "core-app/helpers/dom/set-window-cursor.helper";

export interface DraggableOption {
  name:string;
  id:string;
}

@Component({
  selector: 'draggable-autocompleter',
  templateUrl: './draggable-autocomplete.component.html',
  styleUrls: ['./draggable-autocomplete.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DraggableAutocompleteComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  /** Options to show in the autocompleter */
  @Input() options:DraggableOption[];

  /** Should we focus the autocompleter ? */
  @Input() autofocus:boolean = true;

  /** Order list of selected items */
  @Input('selected') _selected:DraggableOption[] = [];

  /** Output when autocompleter changes values or items removed */
  @Output() onChange = new EventEmitter<DraggableOption[]>();

  /** List of items still available for selection */
  availableOptions:DraggableOption[] = [];

  private autoscroll:any;
  private columnsGroup:Group;

  @ViewChild('ngSelectComponent') public ngSelectComponent:NgSelectComponent;

  text = {
    placeholder: this.I18n.t('js.label_add_columns')
  };

  constructor(readonly I18n:I18nService,
              readonly dragula:DragulaService) {
    super();
  }

  ngOnInit():void {
    this.updateAvailableOptions();

    // Setup groups
    this.columnsGroup = this.dragula.createGroup('columns', {});

    // Set cursor when dragging
    this.dragula.drag('columns')
      .pipe(this.untilDestroyed())
      .subscribe(() => DomHelpers.setBodyCursor('move', 'important'));

    // Reset cursor when cancel or dropped
    merge(
      this.dragula.drop("columns"),
      this.dragula.cancel("columns")
    )
      .pipe(this.untilDestroyed())
      .subscribe(() => DomHelpers.setBodyCursor('auto'));

    // Setup autoscroll
    const that = this;
    this.autoscroll = new DomAutoscrollService(
      [
        document.getElementById('content-wrapper')!
      ],
      {
        margin: 25,
        maxSpeed: 10,
        scrollWhenOutside: true,
        autoScroll: function (this:any) {
          return this.down && that.columnsGroup.drake.dragging;
        }
      });
  }

  ngAfterViewInit():void {
    if (this.autofocus) {
      this.ngSelectComponent.focus();
    }
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    this.dragula.destroy('columns');
  }

  select(item:DraggableOption|undefined) {
    if (!item) {
      return;
    }

    this.selected = [...this.selected, item];

    // Remove selection
    this.ngSelectComponent.clearModel();
  }

  remove(item:DraggableOption) {
    this.selected = this.selected.filter(selected => selected.id !== item.id);
  }

  get selected() {
    return this._selected;
  }

  set selected(val:DraggableOption[]) {
    this._selected = val;
    this.updateAvailableOptions();

    this.onChange.emit(this.selected);
  }

  opened() {
    // Force reposition as a workaround for BUG
    // https://github.com/ng-select/ng-select/issues/1259
    setTimeout(() => {
      const component = this.ngSelectComponent as any;
      if (component && component.dropdownPanel) {
        component.dropdownPanel._updatePosition();
      }
    }, 25);
  }

  private updateAvailableOptions() {
    this.availableOptions = this.options
      .filter(item => !this.selected.find(selected => selected.id === item.id));
  }
}
