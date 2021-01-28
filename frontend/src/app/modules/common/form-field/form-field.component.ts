import {
  Component,
  Input,
  HostBinding,
  ContentChild,
} from "@angular/core";
import {
  FormControlName, FormControl, FormGroup,
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

  @ContentChild(FormControlName, { static: true }) formControlName:FormControlName;
  @ContentChild(FormControl, { static: true }) formControl:FormControl;
  @ContentChild(FormGroup, { static: true }) formGroup:FormGroup;

  get control() {
    return this.formGroup || this.formControlName || this.formControl;
  }

  get isInvalid() {
    return this.control?.touched && this.control?.invalid;
  }
}
