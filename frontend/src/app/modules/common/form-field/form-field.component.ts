import {
  Component,
  Input,
  HostBinding,
  ContentChild,
} from "@angular/core";
import {
  NgControl,
  AbstractControl,
} from "@angular/forms";

@Component({
  selector: 'op-form-field',
  templateUrl: './form-field.component.html',
})
export class OpFormFieldComponent {
  @HostBinding('class.op-form-field') className = true;
  @HostBinding('class.op-form-field_invalid') get errorClassName() {
    return this.isInvalid;
  }

  @Input() label:string = '';
  @Input() required:boolean = false;

  @ContentChild(NgControl) control:NgControl;

  get isDirty() {
    let control:AbstractControl|null = this.control?.control;
    do {
      if (!control) {
        return false;
      }

      if (control.dirty) {
        return true;
      }

      control = control.parent;
    } while (control);

    return false;
  }

  get isInvalid() {
    return this.isDirty && this.control?.invalid;
  }
}
