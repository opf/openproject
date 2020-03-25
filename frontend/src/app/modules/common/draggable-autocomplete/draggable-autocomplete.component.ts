import {ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, ViewChild} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {CdkDragDrop, CdkDragEnd, CdkDragStart, moveItemInArray} from "@angular/cdk/drag-drop";
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
export class DraggableAutocompleteComponent implements OnInit {
  /** Options to show in the autocompleter */
  @Input() options:DraggableOption[];

  /** Order list of selected items */
  @Input('selected') _selected:DraggableOption[] = [];

  /** Output when autocompleter changes values or items removed */
  @Output() onChange = new EventEmitter<DraggableOption[]>();

  /** List of items still available for selection */
  availableOptions:DraggableOption[] = [];

  @ViewChild('ngSelectComponent') public ngSelectComponent:NgSelectComponent;

  text = {
    placeholder: this.I18n.t('js.label_add_columns')
  };

  constructor(readonly I18n:I18nService) {
  }

  ngOnInit():void {
    this.updateAvailableOptions();
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

  onItemMoved(event:CdkDragDrop<DraggableOption[]>) {
    moveItemInArray(this.selected, event.previousIndex, event.currentIndex);
  }


  startDragging($event:CdkDragStart) {
    DomHelpers.setBodyCursor('move', 'important');
  }

  stopDragging($event:CdkDragEnd) {
    DomHelpers.setBodyCursor('auto');
  }

  private updateAvailableOptions() {
    this.availableOptions = this.options
      .filter(item => !this.selected.find(selected => selected.id === item.id));
  }
}
