import {
  Component,
  Input,
} from '@angular/core';

@Component({
  selector: 'sb-form-field-basic',
  templateUrl: './FormFieldBasic.example.html',
})
export class SbFormFieldBasicExampleComponent {
  @Input('label') public label = '';
  @Input('disabled') public disabled = false;
  @Input('open') public dropModalOpen = false;
}
