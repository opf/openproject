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
  Validators,
} from '@angular/forms';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PrincipalType} from '../invite-user.component';

@Component({
  selector: 'op-ium-project-selection',
  templateUrl: './project-selection.component.html',
  styleUrls: ['./project-selection.component.sass'],
})
export class ProjectSelectionComponent implements OnInit {
  @Input() type:PrincipalType;
  @Input() project:any = null;

  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<{project:any, type:string}>();

  public text = {
    title: this.I18n.t('js.invite_user_modal.title.invite'),
    project: {
      required: this.I18n.t('js.invite_user_modal.project.required'),
    },
    type: {
      required: this.I18n.t('js.invite_user_modal.type.required'),
    },
    nextButton: this.I18n.t('js.invite_user_modal.project.next_button'),
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

  projectAndTypeForm = new FormGroup({
    type: new FormControl(PrincipalType.User, [ Validators.required ]),
    project: new FormControl(null, [ Validators.required ]),
  });

  get typeControl() { return this.projectAndTypeForm.get('type'); }
  get projectControl() { return this.projectAndTypeForm.get('project'); }

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}

  ngOnInit() {
    this.typeControl?.setValue(this.type);
    this.projectControl?.setValue(this.project);
  }

  onSubmit($e:Event) {
    $e.preventDefault();
    if (this.projectAndTypeForm.invalid) {
      this.projectAndTypeForm.markAllAsTouched();
      return;
    }

    this.save.emit({
      project: this.projectControl?.value,
      type: this.typeControl?.value,
    });
  }
}
