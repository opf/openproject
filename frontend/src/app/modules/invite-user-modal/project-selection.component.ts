import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import { 
  FormControl,
} from '@angular/forms';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-project-selection',
  templateUrl: './project-selection.component.html',
  styleUrls: ['./project-selection.component.sass'],
})
export class InviteProjectSelectionComponent {
  public text = {
    title: this.I18n.t('js.invite_user_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  public typeOptions = [
    {
      value: 'user',
      title: 'User',
      description: 'Permissions based on the assigned role in the selected project'
    },
    {
      value: 'group',
      title: 'Group',
      description: 'Permissions based on the assigned role in the selected project'
    },
    {
      value: 'placeholder',
      title: 'Placeholder',
      description: 'Has no access to the proejct and no emails are sent out'
    },
  ];

  public type:string = '';
  @Input('type') set parentType(value:string) {
    this.type = value;
  }
  public project:any = null;
  @Input() set parentProject(value:any) {
    this.project = value;
  }

  @Output('close') closeModal = new EventEmitter<void>();
  @Output() save = new EventEmitter<{project:any, type:string}>();

  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef) {}

  close() {
    this.closeModal.emit();
  }

  submit() {
    this.save.emit({
      project: this.project,
      type: this.type,
    });
  }

  back() {
  }
}
