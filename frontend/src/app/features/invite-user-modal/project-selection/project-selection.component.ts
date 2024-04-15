import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnInit,
  Output,
} from '@angular/core';
import {
  AbstractControl,
  UntypedFormControl,
  UntypedFormGroup,
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
import { IProjectAutocompleteItem } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'op-ium-project-selection',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-selection.component.html',
})
export class ProjectSelectionComponent implements OnInit {
  @Input() type:PrincipalType;

  @Input() project:ProjectResource|null;

  // eslint-disable-next-line @angular-eslint/no-output-native
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
    cancelButton: this.I18n.t('js.button_cancel'),
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

  projectAndTypeForm = new UntypedFormGroup({
    // eslint-disable-next-line @typescript-eslint/unbound-method
    type: new UntypedFormControl(PrincipalType.User, [Validators.required]),
    // eslint-disable-next-line @typescript-eslint/unbound-method
    project: new UntypedFormControl(null, [Validators.required], ProjectAllowedValidator(this.currentUserService)),
  });

  get typeControl():AbstractControl {
    return this.projectAndTypeForm.get('type') as AbstractControl;
  }

  get projectControl():AbstractControl {
    return this.projectAndTypeForm.get('project') as AbstractControl;
  }

  private projectInviteCapabilities:ICapability[] = [];

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly bannersService:BannersService,
    readonly apiV3Service:ApiV3Service,
    readonly currentUserService:CurrentUserService,
    readonly cdRef:ChangeDetectorRef,
  ) {}

  ngOnInit():void {
    this.typeControl.setValue(this.type);

    if (this.project) {
      this.projectControl.setValue(cloneHalResource<ProjectResource>(this.project));
    }

    this.setPlaceholderOption();

    this
      .currentUserService
      .capabilities$(['memberships/create'], null)
      .pipe(
        map((capabilities) => capabilities.filter((c) => c._links.action.href.endsWith('/memberships/create'))),
      )
      .subscribe((projectInviteCapabilities) => {
        this.projectInviteCapabilities = projectInviteCapabilities;
        this.cdRef.detectChanges();
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

    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    const projectId = idFromLink(this.projectControl?.value?.href);
    const project = await firstValueFrom(this.apiV3Service.projects.id(projectId).get());

    this.save.emit({
      project,
      type: this.typeControl.value as string,
    });
  }

  APIFiltersForProjects:IAPIFilter[] = [{ name: 'active', operator: '=', values: ['t'] }];

  projectFilterFn(projects:IProjectAutocompleteItem[]):IProjectAutocompleteItem[] {
    const mapped = projects.map((project) => {
      const disabled = !this.projectInviteCapabilities.find((cap) => idFromLink(cap._links.context.href) === project.id.toString());
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
