import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {PrincipalType} from '../invite-user.component';

@Component({
  selector: 'op-ium-summary',
  templateUrl: './summary.component.html',
  styleUrls: ['./summary.component.sass'],
})
export class SummaryComponent {
  @Input() type:PrincipalType;
  @Input() project:any = null;
  @Input() role:any = null;
  @Input() principal:any = null;
  @Input() message:string = '';

  @Output() close = new EventEmitter<void>();
  @Output() back = new EventEmitter<void>();
  @Output() save = new EventEmitter();

  public text = {
    title: () => this.I18n.t('js.invite_user_modal.title.invite_principal_to_project', {
      principal: this.principal?.name,
      project: this.project?.name,
    }),
    projectLabel: this.I18n.t('js.invite_user_modal.project.label'),
    principalLabel: {
      user: this.I18n.t('js.invite_user_modal.principal.label.name_or_email'),
      placeholder: this.I18n.t('js.invite_user_modal.principal.label.name'),
      group: this.I18n.t('js.invite_user_modal.principal.label.name'),
    },
    roleLabel: () => this.I18n.t('js.invite_user_modal.role.label', {
      project: this.project?.name,
    }),
    messageLabel: this.I18n.t('js.invite_user_modal.message.label'),
    backButton: this.I18n.t('js.invite_user_modal.back'),
    nextButton: () => this.I18n.t('js.invite_user_modal.summary.next_button', {
      type: this.type,
      principal: this.principal,
    }),
  };

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly api:APIV3Service,
  ) {}

  async invite() {
    const principal = await (async () => {
      if (this.principal.id) {
        return this.principal;
      }

      switch (this.type) {
        case 'user':
          /*
          return this.api.users.post({
            email: this.principal.name,
            firstName: this.principal.email,
            status: 'invited',
          });
          */
        //case 'group':
        default:
        /*
          return this.api.groups.post({ name: this.principal.name });
          */
        /*
        case 'placeholder':
          return this.api.placeholders.post({ name: this.principal.name });
        */
      }
    })();

    /*
    return this.api.memberships.post({
      principal,
      project: this.project,
      roles: [this.role],
    });
    */
  }

  async onSubmit($e:Event) {
    $e.preventDefault();

    this.save.emit({ principal: this.principal });
  }
}
