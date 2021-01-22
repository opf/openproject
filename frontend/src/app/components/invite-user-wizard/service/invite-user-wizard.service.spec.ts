import { TestBed } from '@angular/core/testing';

import { InviteUserWizardService } from './invite-user-wizard.service';

describe('InviteUserWizardService', () => {
  let service: InviteUserWizardService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(InviteUserWizardService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
