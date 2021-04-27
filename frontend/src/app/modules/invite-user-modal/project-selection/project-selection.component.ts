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
import { take } from "rxjs/operators";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { BannersService } from "core-app/modules/common/enterprise/banners.service";
import { CurrentUserService } from 'core-app/modules/current-user/current-user.service';
import { IOpOptionListOption } from "core-app/modules/common/option-list/option-list.component";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { PrincipalType } from '../invite-user.component';

@Component({
  selector: 'op-ium-project-selection',
  templateUrl: './project-selection.component.html',
  styleUrls: ['./project-selection.component.sass'],
})
export class ProjectSelectionComponent implements OnInit {
  @Input() type:PrincipalType;
  @Input() project:ProjectResource|null;

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
    type: new FormControl(PrincipalType.User, [ Validators.required ]),
    project: new FormControl(null, [ Validators.required ]),
  });

  get typeControl() { return this.projectAndTypeForm.get('type'); }
  get projectControl() { return this.projectAndTypeForm.get('project'); }

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
      this.currentUserService.capabilities$.pipe(take(1)).subscribe((capabilities) => {
        if (!capabilities.find(c => c.action.href.endsWith('/placeholder_users/read'))) {
          return;
        }
        // We only add the option if the user has placeholder read rights
        this.typeOptions.push({
          value: PrincipalType.Placeholder,
          title: this.I18n.t('js.invite_user_modal.type.placeholder.title'),
          description: this.I18n.t('js.invite_user_modal.type.placeholder.description'),
          disabled: false,
        });
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
