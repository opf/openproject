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
import {PrincipalType} from '../invite-user.component';

@Component({
  selector: 'op-ium-message',
  templateUrl: './message.component.html',
  styleUrls: ['./message.component.sass'],
})
export class MessageComponent implements OnInit {
  @Input() type:PrincipalType;
  @Input() project:any = null;
  @Input() principal:any = null;
  @Input() message:string = '';

  @Output() close = new EventEmitter<void>();
  @Output() back = new EventEmitter<void>();
  @Output() save = new EventEmitter<{message:string}>();

  public text = {
    title: () => this.I18n.t('js.invite_user_modal.title.invite_principal_to_project', {
      principal: this.principal?.name,
      project: this.project?.name,
    }),
    label: this.I18n.t('js.invite_user_modal.message.label'),
    description: () => this.I18n.t('js.invite_user_modal.message.description', {
      principal: this.principal?.name,
    }),
    backButton: this.I18n.t('js.invite_user_modal.back'),
    nextButton: this.I18n.t('js.invite_user_modal.message.next_button'),
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

    this.save.emit({ message: this.messageControl?.value });
  }
}
