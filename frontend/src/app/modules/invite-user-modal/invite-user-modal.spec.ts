import {
  async,
  ComponentFixture,
  ComponentFixtureAutoDetect,
  fakeAsync,
  TestBed,
  tick
} from '@angular/core/testing';

import { InviteUserWizardComponent } from './invite-user-wizard.component';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {InviteUserWizardService} from "core-components/invite-user-wizard/service/invite-user-wizard.service";
import {FormBuilder, ReactiveFormsModule} from "@angular/forms";
import {CommonModule} from "@angular/common";
import {NgSelectModule} from "@ng-select/ng-select";
import {NgOptionHighlightModule} from "@ng-select/ng-option-highlight";
import {of} from "rxjs";

describe('InviteUserWizardComponent', () => {
  let component:InviteUserWizardComponent;
  let fixture:ComponentFixture<InviteUserWizardComponent>;
  let hostElement:any;
  let inviteUserWizardServiceSpy:any;
  const users = [
    {
      name: 'user1',
      email: 'user1@email.com',
      id: '1',
    },
    {
      name: 'user2',
      email: 'user2@email.com',
      id: '2',
    },
    {
      name: 'user3',
      email: 'user3@email.com',
      id: '3',
    }
  ];
  const roles = [
    {
      name: 'role1',
      id: '1',
    },
    {
      name: 'role2',
      id: '2',
    },
    {
      name: 'role3',
      id: '3',
    }
  ];

  beforeEach(async(() => {
    inviteUserWizardServiceSpy = jasmine.createSpyObj(
      'InviteUserWizardService',
      ['inviteUser', 'getRoles', 'getPrincipals', 'finalAction'],
    );

    TestBed.configureTestingModule({
      declarations: [ InviteUserWizardComponent ],
      imports: [
        CommonModule,
        ReactiveFormsModule,
        NgSelectModule,
        NgOptionHighlightModule,
      ],
      providers: [
        {provide: ComponentFixtureAutoDetect, useValue: true},
        {provide: CurrentProjectService, useValue: {name: 'project1', id: '1'}},
        {provide: I18nService, useValue: {t: () => ({})}},
        FormBuilder,
      ]
    })
    .overrideComponent(InviteUserWizardComponent, {
      set: {
        providers: [
          {provide: InviteUserWizardService, useValue: inviteUserWizardServiceSpy},
        ]
      }
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(InviteUserWizardComponent);
    component = fixture.componentInstance;
    hostElement = fixture.nativeElement;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should guide to fill the form in steps', fakeAsync(() => {
    const currentProjectService = fixture.debugElement.injector.get(CurrentProjectService);
    let ngSelectInput;
    let nextButton = hostElement.querySelector('.button-right');
    let options;
    let stepContainer;

    inviteUserWizardServiceSpy.getPrincipals.and.returnValue(of(users));
    inviteUserWizardServiceSpy.getRoles.and.returnValue(of(roles));
    inviteUserWizardServiceSpy.inviteUser.and.returnValue(of(true));
    inviteUserWizardServiceSpy.finalAction.and.returnValue(of(true));

    // STEP 1: USER
      expect(nextButton.disabled).toBeTrue();

      ngSelectInput = hostElement.querySelector('input[role="combobox"]');
      ngSelectInput.value = 'a';
      ngSelectInput.dispatchEvent(new Event('input'));

      tick(200);

      options = hostElement.querySelectorAll('.ng-option');
      options[0].click();

      tick(200);

      expect(inviteUserWizardServiceSpy.getPrincipals).toHaveBeenCalled();
      expect(component.form.get('user')!.value).toBe(users[0]);
      expect(nextButton.disabled).toBeFalse();

      nextButton.click();


      // STEP 2: ROLE
      expect(nextButton.disabled).toBeTrue();

      ngSelectInput = hostElement.querySelector('input[role="combobox"]');
      ngSelectInput.value = 'r';
      ngSelectInput.dispatchEvent(new Event('input'));

      tick(200);

      options = hostElement.querySelectorAll('.ng-option');
      options[0].click();

      expect(inviteUserWizardServiceSpy.getRoles).toHaveBeenCalled();
      expect(component.form.get('role')!.value).toBe(roles[0]);
      expect(nextButton.disabled).toBeFalse();

      nextButton.click();


      // STEP 3: MESSAGE
      const message = 'hi';

      expect(nextButton.disabled).toBeTrue();

      const textarea = hostElement.querySelector('textarea');
      textarea.value = message;
      textarea.dispatchEvent(new Event('input'));

      tick(200);

      expect(component.form.get('message')!.value).toBe(message);
      expect(nextButton.disabled).toBeFalse();

      nextButton.click();


      // STEP 4: CONFIRMATION/SEND
      expect(nextButton.disabled).toBeFalse();

      stepContainer = hostElement.querySelector('.step');

      expect(stepContainer.textContent).toContain(component.form.get('user')!.value.name);
      expect(stepContainer.textContent).toContain(component.form.get('role')!.value.name);
      expect(stepContainer.textContent).toContain(component.form.get('message')!.value);

      nextButton.click();

      expect(inviteUserWizardServiceSpy.inviteUser).toHaveBeenCalledWith(
        currentProjectService.id!,
        component.form.get('user')!.value?.id,
        component.form.get('role')!.value?.id,
        component.form.get('message')!.value,
      );

      // STEP 5:DONE
      stepContainer = hostElement.querySelector('.step-confirmation');

      expect(stepContainer).toBeTruthy();

      nextButton.click();

      expect(inviteUserWizardServiceSpy.finalAction).toHaveBeenCalled();
  }));
});
