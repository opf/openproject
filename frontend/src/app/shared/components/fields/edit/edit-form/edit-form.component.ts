//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationRef, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, Injector, Input, OnDestroy, OnInit, Output, inject } from '@angular/core';
import { StateService, Transition, TransitionService } from '@uirouter/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { EditableAttributeFieldComponent } from 'core-app/shared/components/fields/edit/field/editable-attribute-field.component';
import { input } from '@openproject/reactivestates';
import { filter, map, take } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  activeFieldClassName,
  activeFieldContainerClassName,
  EditForm,
} from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { EditingPortalService } from 'core-app/shared/components/fields/edit/editing-portal/editing-portal-service';
import { EditFormRoutingService } from 'core-app/shared/components/fields/edit/edit-form/edit-form-routing.service';
import { ResourceChangesetCommit } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { GlobalEditFormChangesTrackerService } from 'core-app/shared/components/fields/edit/services/global-edit-form-changes-tracker/global-edit-form-changes-tracker.service';
import { firstValueFrom } from 'rxjs';
import * as Turbo from '@hotwired/turbo';

@Component({
  selector: 'edit-form,[edit-form]',
  template: '<ng-content />',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class EditFormComponent extends EditForm<HalResource> implements OnInit, OnDestroy {
  readonly injector:Injector;
  protected readonly elementRef = inject(ElementRef);
  private appRef = inject(ApplicationRef);
  private readonly cdRef = inject(ChangeDetectorRef);
  protected readonly $transitions = inject(TransitionService);
  protected readonly configurationService = inject(ConfigurationService);
  protected readonly editingPortalService = inject(EditingPortalService);
  protected readonly $state = inject(StateService);
  protected readonly I18n = inject(I18nService);
  protected readonly editFormRouting = inject(EditFormRoutingService, { optional: true });
  private globalEditFormChangesTrackerService = inject(GlobalEditFormChangesTrackerService);

  @Input() resource:HalResource;

  @Input('inEditMode') initializeEditMode = false;

  @Input() skippedFields:string[] = [];

  @Output('onSaved') onSavedEmitter = new EventEmitter<{ savedResource:HalResource, isInitial:boolean }>();

  public fields:Record<string, EditableAttributeFieldComponent> = {};

  private registeredFields = input<string[]>();

  private unregisterListener:Function;

  constructor() {
    const injector = inject(Injector);

    super(injector);
    this.injector = injector;
    const $transitions = this.$transitions;
    const I18n = this.I18n;

    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = this.configurationService.warnOnLeavingUnsaved();

    this.unregisterListener = $transitions.onBefore({}, (transition:Transition) => {
      if (!this.editing) {
        return undefined;
      }

      // Show confirmation message when transitioning to a new state
      // that's not within the edit mode.
      if (!this.editFormRouting || this.editFormRouting.blockedTransition(transition)) {
        if (requiresConfirmation && !window.confirm(confirmText)) {
          this.undoCanceledBrowserBackTransition(transition);
          return false;
        }

        this.cancel(false);
      }

      return true;
    });
  }

  private undoCanceledBrowserBackTransition(transition:Transition) {
    if (transition.options().source !== 'url') {
      return;
    }

    const fromUrl = transition
      .router
      .stateService
      .href(transition.from(), transition.params('from'));

    if (!fromUrl) {
      return;
    }

    // Restore the canceled Back URL without firing a real forward navigation,
    // which would make Turbo restore a stale snapshot of the split view.
    Turbo.session
      .history
      .push(new URL(fromUrl, window.location.origin));

    // Keep UI-Router from replacing the restored browser history entry while
    // it rolls back the aborted Back navigation.
    transition.router.urlRouter.update(true);
  }

  ngOnInit() {
    this.editMode = this.initializeEditMode;
    this.globalEditFormChangesTrackerService.addToActiveForms(this);

    if (this.initializeEditMode) {
      this.start();
    }
  }

  ngOnDestroy() {
    this.unregisterListener();
    this.globalEditFormChangesTrackerService.removeFromActiveForms(this);
  }

  public async activateField(form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<EditFieldHandler> {
    return this.waitForField(fieldName).then((ctrl) => {
      ctrl.setActive(true);
      const container = ctrl.editContainer.nativeElement;
      return this.editingPortalService.create(
        container,
        this.injector,
        form,
        schema,
        fieldName,
        errors,
      );
    });
  }

  public async reset(fieldName:string, focus = false) {
    const ctrl = await this.waitForField(fieldName);
    ctrl.reset();
    ctrl.deactivate(focus);
  }

  public onSaved(commit:ResourceChangesetCommit) {
    this.cancel(false);
    this.onSavedEmitter.emit({ savedResource: commit.resource, isInitial: commit.wasNew });
  }

  public cancel(reset = false) {
    this.editMode = false;
    this.closeEditFields('all', reset);

    if (reset) {
      this.halEditing.reset(this.change);
    }
  }

  public requireVisible(fieldName:string):Promise<void> {
    return new Promise<void>((resolve, _) => {
      const interval = setInterval(() => {
        const field = this.fields[fieldName];

        if (field !== undefined) {
          clearInterval(interval);
          resolve();
        }
      }, 50);
    });
  }

  public get editing():boolean {
    return this.editMode || this.hasActiveFields();
  }

  public register(field:EditableAttributeFieldComponent) {
    this.fields[field.fieldName] = field;
    this.registeredFields.putValue(_.keys(this.fields));

    const shouldActivate = (this.editMode && !this.skipField(field) || this.activeFields[field.fieldName]);

    if (shouldActivate) {
      field.activateOnForm(true);
    }
  }

  public waitForField(name:string):Promise<EditableAttributeFieldComponent> {
    return firstValueFrom(this.registeredFields
      .values$()
      .pipe(
        filter((keys) => keys.includes(name)),
        take(1),
        map(() => this.fields[name]),
      ));
  }

  public start() {
    _.each(this.fields, (ctrl) => this.activate(ctrl.fieldName));
  }

  protected focusOnFirstError():void {
    this.cdRef.detectChanges();
    // Focus the first field that is erroneous
    this.elementRef.nativeElement
      .querySelector(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
      ?.focus();
  }

  private skipField(field:EditableAttributeFieldComponent) {
    const { fieldName } = field;

    const isSkipField = this.skippedFields.includes(fieldName);

    // Only skip status or type
    if (!isSkipField) {
      return false;
    }

    // Only skip if value present and not changed in changeset
    const hasDefault = this.resource[fieldName];
    const changed = this.change.changes[fieldName];

    return hasDefault && !changed;
  }
}
