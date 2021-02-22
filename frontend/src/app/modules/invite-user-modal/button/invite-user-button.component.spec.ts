import { ComponentFixture, TestBed } from '@angular/core/testing';

import { InviteUserButtonComponent } from './invite-user-button.component';

describe('InviteUserButtonComponent', () => {
  let component: InviteUserButtonComponent;
  let fixture: ComponentFixture<InviteUserButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ InviteUserButtonComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(InviteUserButtonComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
