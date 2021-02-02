import {Component, ElementRef, HostListener, NgZone, OnInit, ViewChild} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from "@angular/forms";
import {Observable, Subject} from "rxjs";
import {debounceTime, distinctUntilChanged, switchMap} from "rxjs/operators";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {RoleResource} from "core-app/modules/hal/resources/role-resource";
import {NgSelectComponent} from "@ng-select/ng-select";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {InviteUserWizardService} from "core-components/invite-user-wizard/service/invite-user-wizard.service";

@Component({
  selector: 'op-invite-user-wizard',
  templateUrl: './invite-user-wizard.component.html',
  styleUrls: ['./invite-user-wizard.component.scss'],
  providers: [InviteUserWizardService]
})
export class InviteUserWizardComponent extends UntilDestroyedMixin implements OnInit {
  currentStepIndex = 0;
  form:FormGroup;
  steps:IUserWizardStep[];

  get user() {
    return this.form.get('user')?.value;
  }
  get project() {
    return this.form.get('project')?.value;
  }
  get type() {
    return this.form.get('type')?.value;
  }

  get title() {
    if (!this.project || !this.type) {
      return this.I18n.t('js.invite_user_modal.title.invite');
    } else if (!this.user) {
      return this.I18n.t('js.invite_user_modal.title.invite_to_project', {
        project: this.project.name,
        // TODO: this should become a nested translation when we have the possibility
        type: this.I18n.t(`js.invite_user_modal.title.${this.type}`),
      });
    }
    return this.I18n.t('js.invite_user_modal.title.invite_principal_to_project', {
      project: this.project.name,
      principal: this.user.name,
    });
  }

  get alreadyMemberMessage() {
    return this.I18n.t('js.invite_user_modal.already_member_message', { project: this.project?.name });
  }

  noDataFoundFor(searchTerm:string) {
    return this.I18n.t('js.invite_user_modal.no_data_found_for', { searchTerm });
  }

  text = {
    closePopup: this.I18n.t('js.close_popup_title'),
    user: this.I18n.t('js.invite_user_modal.user'),
    previousButtonText: this.I18n.t('js.invite_user_modal.back'),
    project: {
      label: this.I18n.t('js.invite_user_modal.project.label'),
      required: this.I18n.t('js.invite_user_modal.project.required'),
      nextButtonText: this.I18n.t('js.invite_user_modal.project.next_button'),
    },
    type: {
      required: this.I18n.t('js.invite_user_modal.type.required'),
      user: {
        title: this.I18n.t('js.invite_user_modal.user.title'),
        description: this.I18n.t('js.invite_user_modal.user.description'),
      },
      group: {
        title: this.I18n.t('js.invite_user_modal.group.title'),
        description: this.I18n.t('js.invite_user_modal.group.description'),
      },
      placeholder: {
        title: this.I18n.t('js.invite_user_modal.placeholder.title'),
        description: this.I18n.t('js.invite_user_modal.placeholder.description'),
      },
    },
    principal: {
      nextButtonText: this.I18n.t('js.invite_user_modal.principal.next_button'),
    },
    name_or_email: {
      label: this.I18n.t('js.invite_user_modal.name_or_email.label'),
      description: () => this.I18n.t('js.invite_user_modal.name_or_email.description'),
      required: this.I18n.t('js.invite_user_modal.name_or_email.required'),
    },
    role: {
      label: this.I18n.t('js.invite_user_modal.role.label'),
      description: () => this.I18n.t('js.invite_user_modal.role.description', {
        user: this.userToInvite,
        href: 'https://docs.openproject.org/system-admin-guide/users-permissions/',
      }),
      required: this.I18n.t('js.invite_user_modal.role.required'),
      nextButtonText: this.I18n.t('js.invite_user_modal.role.next_button'),
    },
    message: {
      label: this.I18n.t('js.invite_user_modal.message.label'),
      description: () => this.I18n.t('js.invite_user_modal.message.description', {user: this.userToInvite}),
      nextButtonText: this.I18n.t('js.invite_user_modal.message.next_button'),
    },
    summary: {
      nextButtonText: this.I18n.t('js.invite_user_modal.summary.next_button'),
    },
    success: {
      description: () => this.I18n.t('js.invite_user_modal.success.description', {project: this.project}),
      nextButtonText: this.I18n.t('js.invite_user_modal.success.continue'),
    }
  };
  input$ = new Subject<string | null>();
  items$:Observable<any>;

  get ngSelectInput():HTMLInputElement {
    return this.ngSelect.searchInput.nativeElement;
  }

  get currentStep() {
    return this.steps[this.currentStepIndex];
  }

  get userToInvite () {
    return !!this.user?.name;
  }

  @ViewChild('stepBody') stepBody:ElementRef;
  @ViewChild('ngselect') ngSelect:NgSelectComponent;

  @HostListener('document:keydown.enter', ['$event']) onKeydownHandler(event:KeyboardEvent) {
    this.nextAction(this.currentStep);
  }

  constructor(
    private formBuilder:FormBuilder,
    readonly I18n:I18nService,
    private currentProjectService:CurrentProjectService,
    private inviteUserWizardService:InviteUserWizardService,
    private ngZone:NgZone,
  ) {
    super();
  }

  ngOnInit():void {
    // TODO: Remove hardcoded type form value
    this.form = this.formBuilder.group({
      project: [null, Validators.required],
      type: [null, Validators.required],
      user: [null, Validators.required],
      role: [null, Validators.required],
      message: '',
    });
    this.steps = [
      {
        name: 'project-selection',
        fields: [
          {
            type: 'select',
            label: () => this.text.project.label,
            bindLabel: 'name',
            formControlName: 'project',
            apiCallback: this.projectsCallback,
            invalidText: this.text.project.required,
          },
          {
            type: 'option-list',
            formControlName: 'type',
            apiCallback: this.usersCallback,
            invalidText: this.text.type.required,
            options:[
              {
                value: 'user',
                title: this.text.type.user.title,
                description: this.text.type.user.description,
              },
              {
                value: 'group',
                title: this.text.type.group.title,
                description: this.text.type.group.description,
              },
              {
                value: 'placeholder',
                title: this.text.type.placeholder.title,
                description: this.text.type.placeholder.description,
              },
            ],
          },
        ],
        nextButtonText: this.text.project.nextButtonText,
        showInviteUserByEmail: true,
      },
      {
        name: 'user',
        fields: [
          {
            type: 'select',
            label: () => this.text.name_or_email.label,
            bindLabel: 'name',
            formControlName: 'user',
            apiCallback: this.usersCallback,
            description: this.text.name_or_email.description,
            invalidText: this.text.name_or_email.required,
          },
        ],
        nextButtonText: this.text.principal.nextButtonText,
        previousButtonText: this.text.previousButtonText,
        showInviteUserByEmail: true,
      },
      {
        name: 'role',
        fields: [
          {
            type: 'select',
            label: () => `${this.text.role.label} ${this.project}`,
            bindLabel: 'name',
            formControlName: 'role',
            apiCallback: this.rolesCallback,
            description: this.text.role.description,
            invalidText: this.text.role.required,
          }
        ],
        nextButtonText: this.text.role.nextButtonText,
        previousButtonText: this.text.previousButtonText,
      },
      {
        name: 'message',
        fields: [
          {
            type: 'textarea',
            label: () => this.text.message.label,
            formControlName: 'message',
            description: this.text.message.description,
          },
        ],
        nextButtonText: this.text.message.nextButtonText,
        previousButtonText: this.text.previousButtonText,
      },
      {
        name: 'summary',
        fields: [
          {
            type: 'summary',
            label: () => this.text.project.label,
            formControlName: 'project',
          },
          {
            type: 'summary',
            label: () => this.text.name_or_email.label,
            formControlName: 'user',
          },
          {
            type: 'summary',
            label: () => this.text.message.label,
            formControlName: 'message',
          },
        ],
        action: this.inviteUser,
        nextButtonText: this.text.summary.nextButtonText,
        previousButtonText: this.text.previousButtonText,
      },
      {
        name: 'success',
        fields: [],
        nextButtonText: this.text.success.nextButtonText,
        action: this.finalAction,
      },
    ];

    this.items$ = this.input$
      .pipe(
        this.untilDestroyed(),
        debounceTime(200),
        distinctUntilChanged(),
        switchMap(searchTerm => this.currentStep.fields.find((f:IUserWizardStepField) => f.apiCallback)?.apiCallback!(searchTerm!)),
      );
  }

  previousAction() {
    this.currentStepIndex && --this.currentStepIndex;
  }

  nextAction(currentStep:IUserWizardStep) {
    if (this.isInvalidStep(currentStep)) {
      currentStep.fields.forEach((field:IUserWizardStepField) => {
        const formControl = this.form.get(field?.formControlName || '');
        formControl?.markAllAsTouched();
        formControl?.markAsTouched();
      });
      return;
    }

    if (currentStep.action) {
      // TODO: Handle error
      currentStep.action().subscribe(() => {
        this.goToNextStep();
      });
    } else {
      this.goToNextStep();
    }
  }

  goToNextStep() {
    if (this.currentStepIndex < this.steps.length - 1) {
      ++this.currentStepIndex;

      this.focusStepInput();
    }
  }

  focusStepInput() {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.stepBody.nativeElement?.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        )[0]?.focus();
      });
    });
  }

  isInvalidStep(step:IUserWizardStep) {
    return step.fields.reduce((oneInvalid:boolean, field:IUserWizardStepField) => {
      return oneInvalid || this.form.get(field.formControlName || '')?.invalid;
    }, false);
  }

  inputIsEmail(inputValue:string) {
    return !!inputValue?.includes('@');
  }

  inputIsValidEmail(inputValue:string) {
    const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

    return re.test(String(inputValue).toLowerCase());
  }

  setUserEmail(inputValue:string) {
    const user = {name: inputValue, email: inputValue, isEmail: true};

    this.form.get('user')!.setValue(user);
    this.ngSelect.close();
  }

  inviteUser = () => {
    return this.inviteUserWizardService
                  .inviteUser(
                    this.currentProjectService.id!,
                    this.form.get('user')!.value?.id,
                    this.form.get('role')!.value?.id,
                    this.form.get('message')!.value,
                  );
                  // TODO: Implement final response (show toast?)
  }

  finalAction = () => {
    return this.inviteUserWizardService.finalAction();
  }

  projectsCallback = (searchTerm:string):Observable<IUserWizardSelectData[]> => {
    return this.inviteUserWizardService.getProjects(searchTerm);
  }

  usersCallback = (searchTerm:string):Observable<IUserWizardSelectData[]> => {
    return this.inviteUserWizardService
                  .getPrincipals(
                    searchTerm,
                    this.form.get('project')!.value?.id!,
                    this.form.get('type')!.value,
                  );
  }

  rolesCallback = (searchTerm:string):Observable<RoleResource[]>  => {
    return this.inviteUserWizardService.getRoles(searchTerm);
  }
}
