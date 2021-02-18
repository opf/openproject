import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
} from '@angular/core';
import {
  FormGroup,
  FormControl,
  Validators,
} from '@angular/forms';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PrincipalType} from '../invite-user.component';

@Component({
  selector: 'op-ium-principal',
  templateUrl: './principal.component.html',
  styleUrls: ['./principal.component.sass'],
})
export class PrincipalComponent implements OnInit {
  @Input() principal:any = null;
  @Input() project:any = null;
  @Input() type:PrincipalType;

  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<{ principal:any, isAlreadyMember:boolean }>();
  @Output() back = new EventEmitter();

  public text = {
    title: () => this.I18n.t('js.invite_user_modal.title.invite_to_project', {
      type: this.I18n.t(`js.invite_user_modal.title.${this.type}`),
      project: this.project.name,
    }),
    label: {
      user: this.I18n.t('js.invite_user_modal.principal.label.name_or_email'),
      placeholder: this.I18n.t('js.invite_user_modal.principal.label.name'),
      group: this.I18n.t('js.invite_user_modal.principal.label.name'),
    },
    inviteUser: () => this.I18n.t('js.invite_user_modal.principal.invite_user', {
      email: this.principalControl?.value?.name,
    }),
    changeUserSelection: this.I18n.t('js.invite_user_modal.principal.change_user_selection'),
    changePlaceholderSelection: this.I18n.t('js.invite_user_modal.principal.change_placeholder_selection'),
    changeGroupSelection: this.I18n.t('js.invite_user_modal.principal.change_group_selection'),
    createNew: {
      placeholder: () => this.I18n.t('js.invite_user_modal.principal.create_new_placeholder', {
        name: this.principalControl?.value?.name
      }),
      group: () => this.I18n.t('js.invite_user_modal.principal.create_new_group', {
        name: this.principalControl?.value?.name
      }),
    },
    required: {
      user: this.I18n.t('js.invite_user_modal.principal.required.user'),
      placeholder: this.I18n.t('js.invite_user_modal.principal.required.placeholder'),
      group: this.I18n.t('js.invite_user_modal.principal.required.group'),
    },
    backButton: this.I18n.t('js.invite_user_modal.back'),
    nextButton: this.I18n.t('js.invite_user_modal.principal.next_button'),
  };

  public principalForm = new FormGroup({
    principal: new FormControl(null, [ Validators.required ]),
  });

  get principalControl() {
    return this.principalForm.get('principal');
  }

  get isNewPrincipal() {
    return typeof this.principalControl?.value === 'string';
  }

  get isMemberOfCurrentProject() {
    return !!this.principalControl?.value?.memberships?.elements?.find((mem:any) => mem.project.id === this.project.id);
  }

  constructor(readonly I18n:I18nService) {}

  ngOnInit() {
    this.principalControl?.setValue(this.principal);
  }

  createNewFromInput(input:string) {
    this.principalControl?.setValue(input);
  }

  onSubmit($e:Event) {
    $e.preventDefault();

    if (this.principalForm.invalid) {
      this.principalForm.markAllAsTouched();
      return;
    }

    this.save.emit({
      principal: this.principalControl?.value,
      isAlreadyMember: this.isMemberOfCurrentProject,
    });
  }
}
