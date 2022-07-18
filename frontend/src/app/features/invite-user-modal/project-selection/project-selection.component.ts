import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {
  AbstractControl,
  FormControl,
  FormGroup,
  Validators,
} from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { IOpOptionListOption } from 'core-app/shared/components/option-list/option-list.component';
import { cloneHalResource } from 'core-app/features/hal/helpers/hal-resource-builder';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { PrincipalType } from '../invite-user.component';
import { ProjectAllowedValidator } from './project-allowed.validator';
import { map } from 'rxjs/operators';
import { CapabilityResource } from 'core-app/features/hal/resources/capability-resource';
import { IProjectAutocompleteItem } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Component({
  selector: 'op-ium-project-selection',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-selection.component.html',
  styleUrls: ['./project-selection.component.sass'],
})
export class ProjectSelectionComponent implements OnInit {
  @Input() type:PrincipalType;

  @Input() project:ProjectResource|null;

  @Output() close = new EventEmitter<void>();

  @Output() save = new EventEmitter<{ project:ProjectResource|null, type:string }>();

  public text = {
    title: this.I18n.t('js.invite_user_modal.title.invite'),
    project: {
      label: this.I18n.t('js.invite_user_modal.project.label'),
      required: this.I18n.t('js.invite_user_modal.project.required'),
      lackingPermission: this.I18n.t('js.invite_user_modal.project.lacking_permission'),
      lackingPermissionInfo: this.I18n.t('js.invite_user_modal.project.lacking_permission_info'),
      noInviteRights: this.I18n.t('js.invite_user_modal.project.no_invite_rights'),
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

  get typeControl():AbstractControl {
    return this.projectAndTypeForm.get('type')!;
  }

  get projectControl():AbstractControl {
    return this.projectAndTypeForm.get('project')!;
  }

  private projectInviteCapabilities:CapabilityResource[] = [];

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly bannersService:BannersService,
    readonly apiV3Service:ApiV3Service,
    readonly currentUserService:CurrentUserService,
  ) {}

  ngOnInit():void {
    this.typeControl.setValue(this.type);

    if (this.project) {
      this.projectControl.setValue(cloneHalResource<ProjectResource>(this.project));
    }

    this.setPlaceholderOption();

    this.currentUserService.capabilities$
      .pipe(
        map((capabilities) => capabilities.filter((c) => c.action.href.endsWith('/memberships/create'))),
      )
      .subscribe((projectInviteCapabilities) => {
        this.projectInviteCapabilities = projectInviteCapabilities;
      });
  }

  private setPlaceholderOption():void {
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

  async onSubmit($e:Event):Promise<void> {
    $e.preventDefault();
    if (this.projectAndTypeForm.invalid) {
      this.projectAndTypeForm.markAsDirty();
      return;
    }

    const projectId = idFromLink(this.projectControl?.value?.href);
    const project = await this.apiV3Service.projects.id(projectId).get().toPromise();

    this.save.emit({
      project,
      type: this.typeControl?.value,
    });
  }

  APIFiltersForProjects = [['active', '=', true]];

  projectFilterFn(projects:IProjectAutocompleteItem[]):IProjectAutocompleteItem[] {
    const mapped = projects.map((project) => {
      const disabled = !this.projectInviteCapabilities.find((cap) => parseInt(cap.context?.id, 10) === project.id);
      return {
        ...project,
        disabled,
        disabledReason: disabled ? this.text.project.noInviteRights : '',
      };
    });

    mapped.sort(
      (a, b) => (a.disabled ? 1 : 0) - (b.disabled ? 1 : 0),
    );

    return mapped;
  }
}
