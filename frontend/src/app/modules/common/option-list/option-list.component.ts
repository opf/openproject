import {
  Component,
  Input,
  Output,
  EventEmitter,
} from "@angular/core";
import { ControlValueAccessor } from "@angular/forms";

export interface IOpOptionListOption<T> {
  value:T;
  title:string;
  description?:string;
}

export type IOpOptionListValue<T> = T|null;

@Component({
  // Style is imported globally
  templateUrl: './option-list.component.html',
  selector: 'op-option-list',
})
export class OpOptionListComponent<T> implements ControlValueAccessor {
  @Input() options:IOpOptionListOption<T>[] = [];
  @Input() name:string = `op-option-list-${+(new Date())}`;
  @Output() selectedChange = new EventEmitter<T>();

  private _selected:IOpOptionListValue<T> = null;
  get selected() {
    return this._selected;
  }
  set selected(data:IOpOptionListValue<T>) {
    this.onChange(data);
  }
  onChange = (_:IOpOptionListValue<T>) => {};
  onTouched = (_:IOpOptionListValue<T>) => {};

  writeValue(value:IOpOptionListValue<T>) {
    this._selected = value;
  }

  registerOnChange(fn:any) {
    this.onChange = fn;
  }

  registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}
