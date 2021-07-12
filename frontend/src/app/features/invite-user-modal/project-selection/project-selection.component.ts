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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { IOpOptionListOption } from 'core-app/shared/components/option-list/option-list.component';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { PrincipalType } from '../invite-user.component';
import { ProjectAllowedValidator } from './project-allowed.validator';

@Component({
  selector: 'op-ium-project-selection',
  templateUrl: './project-selection.component.html',
  styleUrls: ['./project-selection.component.sass'],
})
export class ProjectSelectionComponent implements OnInit {
  @Input() type:PrincipalType;

  @Input() project:ProjectResource|null;

  @Output() close = new EventEmitter<void>();

  @Output() save = new EventEmitter<{ project:any, type:string }>();

  public text = {
    title: this.I18n.t('js.invite_user_modal.title.invite'),
    project: {
      required: this.I18n.t('js.invite_user_modal.project.required'),
      lackingPermission: this.I18n.t('js.invite_user_modal.project.lacking_permission'),
      lackingPermissionInfo: this.I18n.t('js.invite_user_modal.project.lacking_permission_info'),
    },
    type: {
      required: this.I18n.t('js.invite_user_modal.type.required'),
    },
    nextButton: this.I18n.t('js.invite_user_modal.project.next_button'),
  };

  public typeOptions:IOpOptionListOption<string>[] = [
    {
      value: PrincipalType.User,
      title: this.I18n.t('js.invite_user_modal.type.user.title'),
      description: this.I18n.t('js.invite_user_modal.type.user.description'),
    },
    {
      value: PrincipalType.Group,
      title: this.I18n.t('js.invite_user_modal.type.group.title'),
      description: this.I18n.t('js.invite_user_modal.type.group.description'),
    },
  ];

  projectAndTypeForm = new FormGroup({
    type: new FormControl(PrincipalType.User, [Validators.required]),
    project: new FormControl(null, [Validators.required], ProjectAllowedValidator(this.currentUserService)),
  });

  get typeControl() {
    return this.projectAndTypeForm.get('type');
  }

  get projectControl() {
    return this.projectAndTypeForm.get('project');
  }

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly bannersService:BannersService,
    readonly currentUserService:CurrentUserService,
  ) {}

  ngOnInit() {
    this.typeControl?.setValue(this.type);
    this.projectControl?.setValue(this.project);

    this.setPlaceholderOption();
  }

  private setPlaceholderOption() {
    if (this.bannersService.eeShowBanners) {
      this.typeOptions.push({
        value: PrincipalType.Placeholder,
        title: this.I18n.t('js.invite_user_modal.type.placeholder.title_no_ee'),
        description: this.I18n.t('js.invite_user_modal.type.placeholder.description_no_ee', {
          eeHref: this.bannersService.getEnterPriseEditionUrl({
            referrer: 'placeholder-users',
            hash: 'placeholder-users',
          }),
        }),
        disabled: true,
      });
    } else {
      this.typeOptions.push({
        value: PrincipalType.Placeholder,
        title: this.I18n.t('js.invite_user_modal.type.placeholder.title'),
        description: this.I18n.t('js.invite_user_modal.type.placeholder.description'),
        disabled: false,
      });
    }
  }

  onSubmit($e:Event) {
    $e.preventDefault();
    if (this.projectAndTypeForm.invalid) {
      this.projectAndTypeForm.markAsDirty();
      return;
    }

    this.save.emit({
      project: this.projectControl?.value,
      type: this.typeControl?.value,
    });
  }
}
