import {
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {
  FormControl,
  FormGroup,
} from '@angular/forms';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-message',
  templateUrl: './message.component.html',
  styleUrls: ['./message.component.sass'],
})
export class MessageComponent implements OnInit {
  @Input('type') type:string = '';
  @Input('project') project:any = null;
  @Input('principal') principal:any = null;
  @Input('message') message:string = '';

  @Output('close') closeModal = new EventEmitter<void>();
  @Output('back') back = new EventEmitter<void>();
  @Output() save = new EventEmitter<{message:string}>();

  public text = {
    title: this.I18n.t('js.invite_user_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  messageForm = new FormGroup({
    message: new FormControl(''),
  });

  get messageControl() { return this.messageForm.get('message'); }

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}

  ngOnInit() {
    this.messageControl?.setValue(this.message);
  }

  onSubmit($e:Event) {
    $e.preventDefault();
    if (this.messageForm.invalid) {
      this.messageForm.markAllAsTouched();
      return;
    }

    this.save.emit({ message: this.messageForm?.value });
  }
}
