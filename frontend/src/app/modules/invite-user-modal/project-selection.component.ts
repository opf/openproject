import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {
  FormControl,
  FormGroup,
  Validators,
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

  @Input('type') type:string;
  @Input('project') project:null;

  projectAndTypeForm = new FormGroup({
    type: new FormControl('', [ Validators.required ]),
    project: new FormControl(null, [ Validators.required ]),
  });

  get typeControl() { return this.projectAndTypeForm.get('type'); }
  get projectControl() { return this.projectAndTypeForm.get('project'); }

  @Output('close') closeModal = new EventEmitter<void>();
  @Output() save = new EventEmitter<{project:any, type:string}>();

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}

  onSubmit($e:Event) {
    $e.preventDefault();
    this.projectAndTypeForm.markAllAsTouched();
    if (this.projectAndTypeForm.invalid) {
      return;
    }

    this.save.emit({
      project: this.projectAndTypeForm.get('project')?.value,
      type: this.projectAndTypeForm.get('type')?.value,
    });
  }

  close() {
    this.closeModal.emit();
  }
}
