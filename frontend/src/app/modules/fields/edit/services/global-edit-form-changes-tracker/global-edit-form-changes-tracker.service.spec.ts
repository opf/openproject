import { TestBed } from '@angular/core/testing';
import { GlobalEditFormChangesTrackerService } from './global-edit-form-changes-tracker.service';

describe('GlobalEditFormChangesTrackerService', () => {
  let service:GlobalEditFormChangesTrackerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(GlobalEditFormChangesTrackerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should not have model changes when created', () => {
    expect(service.hasModelChanges).toBeFalsy();
  });

  it('should have model changes when one form is added', () => {
    const editForm = 'editForm';

    service.addToFormsWithModelChanges(editForm);

    expect(service.hasModelChanges).toBeTruthy();
  });

  it('should have model changes while there are forms registered', () => {
    const editForm = 'editForm';
    const editForm2 = 'editForm2';

    service.addToFormsWithModelChanges(editForm);
    service.addToFormsWithModelChanges(editForm2);
    service.removeFromFormsWithModelChanges(editForm);

    expect(service.hasModelChanges).toBeTruthy();
  });

  it('should not have model changes when all the form have been removed', () => {
    const editForm = 'editForm';
    const editForm2 = 'editForm2';

    service.addToFormsWithModelChanges(editForm);
    service.addToFormsWithModelChanges(editForm2);
    service.removeFromFormsWithModelChanges(editForm);
    service.removeFromFormsWithModelChanges(editForm2);

    expect(service.hasModelChanges).toBeFalsy();
  });
});
