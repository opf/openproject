import {
  Component,
  Input,
  HostBinding,
} from "@angular/core";
import {
  FormControl,
  FormGroup,
} from "@angular/forms";

@Component({
  // Style is imported globally
  templateUrl: './form-field.component.html',
  selector: 'op-form-field',
})
export class OpFormFieldComponent {
  @HostBinding('class.op-form-field') className = true;
  @HostBinding('class.op-form-field_invalid') get errorClassName() {
    return this.isInvalid;
  }

  @Input() formBinding:FormGroup|FormControl;
  @Input() label:string = '';
  @Input() required:boolean = false;

  get isInvalid() {
    return this.formBinding?.touched && this.formBinding?.invalid;
  }
}
