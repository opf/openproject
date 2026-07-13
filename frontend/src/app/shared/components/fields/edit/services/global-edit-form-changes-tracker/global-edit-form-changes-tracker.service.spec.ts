import { TestBed } from '@angular/core/testing';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { GlobalEditFormChangesTrackerService } from './global-edit-form-changes-tracker.service';

describe('GlobalEditFormChangesTrackerService', () => {
  let service:GlobalEditFormChangesTrackerService;
  let originalOpenProject:OpenProject;
  const createForm = (
    changed?:boolean,
    inFlight = false,
    resourceId:string|null = '1',
    editing = Boolean(changed) || resourceId === null,
  ) => ({
    editing,
    resource: {
      id: resourceId,
    },
    change: {
      inFlight,
      isEmpty: () => !changed,
    },
  } as EditFormComponent);

  beforeEach(() => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();
    TestBed.configureTestingModule({});
    service = TestBed.inject(GlobalEditFormChangesTrackerService);
  });

  afterEach(() => {
    // eslint-disable-next-line @typescript-eslint/dot-notation
    service['abortController'].abort();
    window.OpenProject = originalOpenProject;
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should report no changes when empty', () => {
    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report no changes when one form has no changes', () => {
    const form = createForm();

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report no changes when multiple forms have no changes', () => {
    const form = createForm();
    const form2 = createForm();
    const form3 = createForm();

    service.addToActiveForms(form);
    service.addToActiveForms(form2);
    service.addToActiveForms(form3);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report no changes when the only form with changes is removed', () => {
    const form = createForm(true);

    service.addToActiveForms(form);
    service.removeFromActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report changes when one form has changes', () => {
    const form = createForm(true);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(true);
  });

  it('should report no changes when a changed form is no longer editing', () => {
    const form = createForm(true, false, '1', false);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report no changes when one form is editing without changes', () => {
    const form = {
      ...createForm(),
      editing: true,
    } as EditFormComponent;

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report changes when an unchanged form tracks a new resource', () => {
    const form = createForm(false, false, null);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(true);
  });

  it('should report no changes when a new resource form is no longer editing', () => {
    const form = createForm(false, false, null, false);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report no changes when the only changed form is being saved', () => {
    const form = createForm(true, true);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report no changes when a new resource is being saved', () => {
    const form = createForm(false, true, null);

    service.addToActiveForms(form);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(false);
  });

  it('should report changes when another form has unsaved changes while one is being saved', () => {
    const savingForm = createForm(true, true);
    const changedForm = createForm(true);

    service.addToActiveForms(savingForm);
    service.addToActiveForms(changedForm);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(true);
  });

  it('should report forms with changes when multiple form have changes', () => {
    const form = createForm(true);
    const form2 = createForm(true);
    const form3 = createForm();

    service.addToActiveForms(form);
    service.addToActiveForms(form2);
    service.addToActiveForms(form3);

    expect(service.thereAreFormsWithUnsavedChanges).toBe(true);
  });

  it('should prevent beforeunload when a tracked form has changes', () => {
    const form = createForm(true);
    const event = new Event('beforeunload', { cancelable: true });

    service.addToActiveForms(form);
    window.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('should not prevent beforeunload when the page was submitted', () => {
    const form = createForm(true);
    const event = new Event('beforeunload', { cancelable: true });

    window.OpenProject.pageState = 'submitted';
    service.addToActiveForms(form);
    window.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it('registers an OpenProject callback for edit form changes', () => {
    const form = createForm(true);

    service.addToActiveForms(form);

    expect(window.OpenProject.editFormsContainUnsavedChanges()).toBe(true);
  });

  it('should prevent turbo:before-render for restoration visits when a tracked form has changes', () => {
    const form = createForm(true);
    const event = new Event('turbo:before-render', { cancelable: true });

    service.addToActiveForms(form);
    document.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('should not prevent turbo:before-render when no forms have changes', () => {
    const event = new Event('turbo:before-render', { cancelable: true });

    document.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it('should not prevent turbo:before-render after a non-restore turbo:visit', () => {
    const form = createForm(true);

    service.addToActiveForms(form);
    document.dispatchEvent(new CustomEvent('turbo:visit', { detail: { url: 'http://example.com', action: 'advance' } }));

    const event = new Event('turbo:before-render', { cancelable: true });
    document.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it('should prevent turbo:before-render after a restore turbo:visit', () => {
    const form = createForm(true);

    service.addToActiveForms(form);
    document.dispatchEvent(new CustomEvent('turbo:visit', { detail: { url: 'http://example.com', action: 'restore' } }));

    const event = new Event('turbo:before-render', { cancelable: true });
    document.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('should still block renders when a prior turbo:before-visit was canceled', () => {
    const form = createForm(true);

    service.addToActiveForms(form);

    const canceledVisit = new CustomEvent('turbo:before-visit', {
      detail: { url: 'http://example.com' },
      cancelable: true,
    });
    canceledVisit.preventDefault();
    document.dispatchEvent(canceledVisit);

    const event = new Event('turbo:before-render', { cancelable: true });
    document.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });
});
