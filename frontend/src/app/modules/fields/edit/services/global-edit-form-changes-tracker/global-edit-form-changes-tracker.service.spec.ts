import { TestBed } from '@angular/core/testing';
import { GlobalEditFormChangesTrackerService } from './global-edit-form-changes-tracker.service';
import { EditFormComponent } from "core-app/modules/fields/edit/edit-form/edit-form.component";

describe('GlobalEditFormChangesTrackerService', () => {
  let service:GlobalEditFormChangesTrackerService;
  const createForm = (changed?:boolean) => {
    return {
      change: {
        isEmpty: () => !changed
      }
    } as EditFormComponent;
  };

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(GlobalEditFormChangesTrackerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should report no changes when empty', () => {
    expect(service.thereAreFormsWithUnsavedChanges).toBeFalse();
  });

  it('should report no changes when one form has no changes', () => {
    const form = createForm();

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBeFalse();
  });

  it('should report no changes when multiple forms have no changes', () => {
    const form = createForm();
    const form2 = createForm();
    const form3 = createForm();

    service.addToActiveForms(form);
    service.addToActiveForms(form2);
    service.addToActiveForms(form3);

    expect(service.thereAreFormsWithUnsavedChanges).toBeFalse();
  });

  it('should report no changes when the only form with changes is removed', () => {
    const form = createForm(true);

    service.addToActiveForms(form);
    service.removeFromActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBeFalse();
  });

  it('should report changes when one form has changes', () => {
    const form = createForm(true);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBeTrue();
  });

  it('should report forms with changes when multiple form have changes', () => {
    const form = createForm(true);
    const form2 = createForm(true);
    const form3 = createForm();

    service.addToActiveForms(form);
    service.addToActiveForms(form2);
    service.addToActiveForms(form3);

    expect(service.thereAreFormsWithUnsavedChanges).toBeTrue();
  });

  it('should call thereAreFormsWithUnsavedChangesSpy on beforeunload', () => {
    const thereAreFormsWithUnsavedChangesSpy = spyOnProperty(service, 'thereAreFormsWithUnsavedChanges', 'get');

    window.dispatchEvent(new Event('beforeunload'));

    expect(thereAreFormsWithUnsavedChangesSpy).toHaveBeenCalled();
  });
});
