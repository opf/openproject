import {Component, OnInit, ViewChild} from '@angular/core';
import {FormBuilder, FormGroup} from "@angular/forms";
import {Observable, Subject} from "rxjs";
import {debounceTime, distinctUntilChanged, filter, switchMap} from "rxjs/operators";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
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
  project:string;
  text = {
    title: this.I18n.t('js.invite_user_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing'),
    user: this.I18n.t('js.invite_user_modal.user'),
    nextButtonText: this.I18n.t('js.invite_user_modal.next'),
    previousButtonText: this.I18n.t('js.invite_user_modal.back'),
    invite: this.I18n.t('js.invite_user_modal.invite'),
    to: this.I18n.t('js.invite_user_modal.to'),
    noDataFoundFor: this.I18n.t('js.invite_user_modal.no_data_found_for'),
    step0: {
      label: this.I18n.t('js.invite_user_modal.name_or_email_label'),
      summaryLabel: this.I18n.t('js.invite_user_modal.user'),
      description: () => this.I18n.t('js.invite_user_modal.name_or_email_description'),
    },
    step1: {
      label: this.I18n.t('js.invite_user_modal.role_label'),
      summaryLabel: this.I18n.t('js.invite_user_modal.role'),
      description: () => this.I18n.t('js.invite_user_modal.role_description', {user: this.userToInvite}),
    },
    step2: {
      label: this.I18n.t('js.invite_user_modal.message_label'),
      summaryLabel: this.I18n.t('js.invite_user_modal.message_summary_label'),
      description: () => this.I18n.t('js.invite_user_modal.message_description', {user: this.userToInvite}),
      nextButtonText: this.I18n.t('js.invite_user_modal.message_next_button'),
    },
    step3: {
      nextButtonText: this.I18n.t('js.invite_user_modal.send_invitation'),
    },
    step4: {
      description: () => this.I18n.t('js.invite_user_modal.confirm_description', {project: this.project}),
      nextButtonText: this.I18n.t('js.invite_user_modal.continue'),
    }
  };
  steps:IUserWizardStep[];
  ngSelectInput:HTMLInputElement;
  input$ = new Subject<string | null>();
  items$:Observable<any>;

  get currentStep() {
    return this.steps[this.currentStepIndex];
  }

  get userToInvite () {
    const user = this.form.get('user')!.value;

    return user && user.name;
  }

  @ViewChild('ngselect') ngselect:NgSelectComponent;

  constructor(
    private formBuilder:FormBuilder,
    private apiV3Service:APIV3Service,
    readonly I18n:I18nService,
    private currentProjectService:CurrentProjectService,
    private inviteUserWizardService:InviteUserWizardService,
  ) {
    super();
  }

  ngOnInit():void {
    // TODO: Remove hardcoded type form value
    this.form = this.formBuilder.group({
      type: 'User',
      user: null,
      role: null,
      message: null,
    });
    this.project = this.currentProjectService.name!;
    this.steps = [
      {
        type: 'select',
        label: () => this.text.step0.label,
        summaryLabel: this.text.step0.summaryLabel,
        bindLabel: 'name',
        formControlName: 'user',
        apiCallback: this.usersCallback,
        description: this.text.step0.description,
        nextButtonText: this.text.nextButtonText,
        previousButtonText: this.text.previousButtonText,
        showInviteUserByEmail: true,
      },
      {
        type: 'select',
        label: () => `${this.text.step1.label} ${this.project}`,
        summaryLabel: this.text.step1.summaryLabel,
        bindLabel: 'name',
        formControlName: 'role',
        apiCallback: this.rolesCallback,
        description: this.text.step1.description,
        nextButtonText: this.text.nextButtonText,
        previousButtonText: this.text.previousButtonText,
      },
      {
        type: 'textarea',
        label: () => this.text.step2.label,
        summaryLabel: this.text.step2.summaryLabel,
        formControlName: 'message',
        description: this.text.step2.description,
        nextButtonText: this.text.step2.nextButtonText,
        previousButtonText: this.text.previousButtonText,
      },
      {
        type: 'summary',
        nextButtonText: this.text.step3.nextButtonText,
        previousButtonText: this.text.previousButtonText,
      },
      {
        type: 'confirmation',
        nextButtonText: this.text.step4.nextButtonText,
        description: this.text.step4.description,
      },
    ];

    this.items$ = this.input$
      .pipe(
        this.untilDestroyed(),
        debounceTime(200),
        filter(searchTerm => !!searchTerm),
        distinctUntilChanged(),
        switchMap(searchTerm => this.currentStep.apiCallback!(searchTerm!)),
      );
  }

  ngAfterViewInit() {
    this.ngSelectInput = this.ngselect.searchInput.nativeElement;
  }

  nextStep() {
    if (this.currentStepIndex < this.steps.length - 1) {
      ++this.currentStepIndex;
    } else {
      this.inviteUser();
    }
  }

  previousStep() {
    this.currentStepIndex && --this.currentStepIndex;
  }

  inputIsEmail(inputValue:string) {
    return !!inputValue?.includes('@');
  }

  inputIsValidEmail(inputValue:string) {
    const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

    return re.test(String(inputValue).toLowerCase());
  }

  setUserEmail(inputValue:string) {
    const user = {name: inputValue, isEmail: true};

    this.form.get('user')!.setValue(user);
    this.ngselect.close();
  }

  inviteUser() {
    this.inviteUserWizardService
      .inviteUser(
        this.currentProjectService.id!,
        this.form.get('user')!.value?.id,
        this.form.get('role')!.value?.id
      )
      // TODO: Implement final response (show toast?)
      .subscribe(r => console.log('InviteUser response', r));
  }

  usersCallback = (searchTerm:string):Observable<IUserWizardSelectData[]> => {
    return this.inviteUserWizardService
                  .getPrincipals(
                    searchTerm,
                    this.currentProjectService.id!,
                    this.form.get('type')!.value,
                  );
  }

  rolesCallback = (searchTerm:string):Observable<RoleResource[]>  => {
    return this.inviteUserWizardService.getRoles(searchTerm);
  }
}
