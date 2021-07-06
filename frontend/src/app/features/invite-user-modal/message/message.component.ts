import {
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  ElementRef,
  ViewChild,
} from '@angular/core';
import {
  FormControl,
  FormGroup,
} from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { PrincipalType } from '../invite-user.component';

@Component({
  selector: 'op-ium-message',
  templateUrl: './message.component.html',
  styleUrls: ['./message.component.sass'],
})
export class MessageComponent implements OnInit {
  @Input() type:PrincipalType;

  @Input() project:ProjectResource;

  @Input() principal:HalResource;

  @Input() message = '';

  @Output() close = new EventEmitter<void>();

  @Output() back = new EventEmitter<void>();

  @Output() save = new EventEmitter<{ message:string }>();

  @ViewChild('input') input:ElementRef;

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

  get messageControl() {
    return this.messageForm.get('message');
  }

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}

  ngOnInit() {
    this.messageControl?.setValue(this.message);
  }

  ngAfterViewInit() {
    this.input.nativeElement.focus();
  }

  onSubmit($e:Event) {
    $e.preventDefault();
    if (this.messageForm.invalid) {
      this.messageForm.markAsDirty();
      return;
    }

    this.save.emit({ message: this.messageControl?.value });
  }
}
