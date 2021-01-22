import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { InviteUserWizardComponent } from './invite-user-wizard.component';

describe('InviteUserWizardComponent', () => {
  let component:InviteUserWizardComponent;
  let fixture:ComponentFixture<InviteUserWizardComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ InviteUserWizardComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(InviteUserWizardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
