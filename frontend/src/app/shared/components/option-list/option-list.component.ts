import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, forwardRef, HostBinding, Input, Output, inject } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export interface IOpOptionListOption<T> {
  value:T;
  title:string;
  disabled?:boolean;
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
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class OpOptionListComponent<T> implements ControlValueAccessor {
  private cdRef = inject(ChangeDetectorRef);

  @HostBinding('class.op-option-list') className = true;

  @Input() options:IOpOptionListOption<T>[] = [];

  @Input() name = `op-option-list-${+(new Date())}`;

  @Output() selectedChange = new EventEmitter<T>();

  private _selected:IOpOptionListValue<T> = null;

  get selected() {
    return this._selected;
  }

  set selected(value:IOpOptionListValue<T>) {
    this._selected = value;
    this.onChange(value);
  }

  getClassListForItem(option:IOpOptionListOption<T>) {
    return {
      'op-option-list--item': true,
      'op-option-list--item_selected': this.selected === option.value,
      'op-option-list--item_disabled': !!option.disabled,
    };
  }

  onChange = (_:IOpOptionListValue<T>) => {};

  onTouched = (_:IOpOptionListValue<T>) => {};

  writeValue(value:IOpOptionListValue<T>) {
    this._selected = value;
    this.cdRef.markForCheck();
  }

  registerOnChange(fn:any) {
    this.onChange = fn;
  }

  registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}
