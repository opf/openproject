import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

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

  @Output('close') closeModal = new EventEmitter<void>();
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
  ) {}

  async onSubmit($e:Event) {
    $e.preventDefault();

    // save here

    this.save.emit();
  }
}
