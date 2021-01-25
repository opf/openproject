import {Component, ElementRef, HostListener, NgZone, OnInit, ViewChild} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from "@angular/forms";
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
    rightButtonText: this.I18n.t('js.invite_user_modal.next'),
    leftButtonText: this.I18n.t('js.invite_user_modal.back'),
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
      rightButtonText: this.I18n.t('js.invite_user_modal.message_next_button'),
    },
    step3: {
      rightButtonText: this.I18n.t('js.invite_user_modal.send_invitation'),
    },
    step4: {
      description: () => this.I18n.t('js.invite_user_modal.confirm_description', {project: this.project}),
      rightButtonText: this.I18n.t('js.invite_user_modal.continue'),
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

  @ViewChild('ngselect') select:NgSelectComponent;
  @ViewChild('textarea') textarea:ElementRef;

  @HostListener('document:keydown.enter', ['$event']) onKeydownHandler(event:KeyboardEvent) {
    this.nextStep(this.currentStep);
  }

  constructor(
    private formBuilder:FormBuilder,
    private apiV3Service:APIV3Service,
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
      type: ['User', Validators.required],
      user: [null, Validators.required],
      role: [null, Validators.required],
      message: [null, Validators.required],
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
        rightButtonText: this.text.rightButtonText,
        leftButtonText: this.text.leftButtonText,
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
        rightButtonText: this.text.rightButtonText,
        leftButtonText: this.text.leftButtonText,
      },
      {
        type: 'textarea',
        label: () => this.text.step2.label,
        summaryLabel: this.text.step2.summaryLabel,
        formControlName: 'message',
        description: this.text.step2.description,
        rightButtonText: this.text.step2.rightButtonText,
        leftButtonText: this.text.leftButtonText,
      },
      {
        type: 'summary',
        rightButtonText: this.text.step3.rightButtonText,
        leftButtonText: this.text.leftButtonText,
        action: this.inviteUser,
      },
      {
        type: 'confirmation',
        rightButtonText: this.text.step4.rightButtonText,
        description: this.text.step4.description,
        action: this.finalAction,
      },
    ];

    this.items$ = this.input$
      .pipe(
        this.untilDestroyed(),
        debounceTime(200),
        distinctUntilChanged(),
        switchMap(searchTerm => this.currentStep.apiCallback!(searchTerm!)),
      );
  }

  ngAfterViewInit() {
    this.ngSelectInput = this.select.searchInput.nativeElement;
  }

  previousStep() {
    this.currentStepIndex && --this.currentStepIndex;
  }

  nextStep(currentStep:IUserWizardStep) {
    if (currentStep.formControlName && this.form.get(currentStep.formControlName!)!.invalid) {
      return;
    }

    if (currentStep.action) {
      currentStep.action();
    }

    if (this.currentStepIndex < this.steps.length - 1) {
      ++this.currentStepIndex;

      if (this.currentStep.formControlName) {
        this.focusStepInput(this.currentStep);
      }
    }
  }

  focusStepInput(currentStep:IUserWizardStep) {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        if (currentStep.type === 'select') {
          this.select.focus();
        } else if (currentStep.type === 'textarea') {
          this.textarea.nativeElement.focus();
        }
      });
    });
  }

  shouldBeDisabled(currentStep:IUserWizardStep) {
    return currentStep?.formControlName && this.form.get(currentStep.formControlName)!.invalid;
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
    this.select.close();
  }

  inviteUser = () => {
    this.inviteUserWizardService
      .inviteUser(
        this.currentProjectService.id!,
        this.form.get('user')!.value?.id,
        this.form.get('role')!.value?.id
      )
      // TODO: Implement final response (show toast?)
      .subscribe(() => this.nextStep(this.currentStep));
  }

  finalAction = () => {
    // TODO:  Implement final action (close dialog and set value to the input?)
    console.log('Final action');
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
