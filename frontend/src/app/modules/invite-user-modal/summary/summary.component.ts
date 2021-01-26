import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {APIV3Service} from "core-app/modules/api/api-v3.service";

@Component({
  selector: 'op-ium-summary',
  templateUrl: './summary.component.html',
  styleUrls: ['./summary.component.sass'],
})
export class SummaryComponent {
  @Input('type') type:string = '';
  @Input('project') project:any = null;
  @Input('role') role:any = null;
  @Input('principal') principal:any = null;
  @Input('message') message:string = '';

  @Output('close') close = new EventEmitter<void>();
  @Output('back') back = new EventEmitter<void>();
  @Output() save = new EventEmitter();

  public text = {
    title: this.I18n.t('js.invite_user_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly api: APIV3Service,
  ) {}

  async invite() {
    const principal = await (async () => {
      if (this.principal.id) {
        return this.principal;
      }

      switch (this.type) {
        case 'user':
          return this.api.users.create({
            email: this.principal.name,
            firstName: this.principal.email,
            status: 'invited',
          });
        case 'group':
          return this.api.groups.create({ name: this.principal.name });
        case 'placeholder':
          return this.api.placeholders.create({ name: this.principal.name });
      }
    })();

    return this.api.memberships.create({
      principal,
      project: this.project,
      roles: [this.role],
    });
  }

  async onSubmit($e:Event) {
    $e.preventDefault();

    this.save.emit({ principal: this.principal });
  }
}
