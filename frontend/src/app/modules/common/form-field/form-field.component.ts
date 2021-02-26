import {
  Component,
  Input,
  HostBinding,
  ContentChild,
} from "@angular/core";
import {
  NgControl
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

  get isInvalid() {
    return this.control?.touched && this.control?.invalid;
  }
}
