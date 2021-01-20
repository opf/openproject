import {
  Component,
  Input,
  Output,
  EventEmitter,
  HostBinding,
  forwardRef,
} from "@angular/core";
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
  DefaultValueAccessor,
} from "@angular/forms";

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
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => OpOptionListComponent),
    multi: true,
  }],
})
export class OpOptionListComponent<T> implements ControlValueAccessor {
  @HostBinding('class.op-option-list') className = true;

  @Input() options:IOpOptionListOption<T>[] = [];
  @Input() name:string = `op-option-list-${+(new Date())}`;
  @Output() selectedChange = new EventEmitter<T>();

  private _selected:IOpOptionListValue<T> = null;
  get selected() {
    return this._selected;
  }
  set selected(data:IOpOptionListValue<T>) {
    this._selected = data;
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
