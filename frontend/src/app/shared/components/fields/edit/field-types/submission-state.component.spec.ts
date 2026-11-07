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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector, Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { EMPTY, Subject, firstValueFrom } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { initializeHalProperties } from 'core-app/features/hal/helpers/hal-resource-builder';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { CustomActionResource } from 'core-app/features/hal/resources/custom-action-resource';
import { SchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { WpCustomActionComponent } from 'core-app/features/work-packages/components/wp-custom-actions/wp-custom-actions/wp-custom-action.component';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResourceEditingService } from '../services/hal-resource-editing.service';
import { HalResourceEditFieldHandler } from '../field-handler/hal-resource-edit-field-handler';
import { EditForm } from '../edit-form/edit-form';
import { EditFieldHandler } from '../editing-portal/edit-field-handler';
import { EditFieldComponent, OpEditingPortalChangesetToken, OpEditingPortalHandlerToken, OpEditingPortalSchemaToken } from '../edit-field.component';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { TextEditFieldComponent } from './text-edit-field/text-edit-field.component';
import { PlainFormattableEditFieldComponent } from './plain-formattable-edit-field.component';
import { BooleanEditFieldComponent } from './boolean-edit-field/boolean-edit-field.component';
import { IntegerEditFieldComponent } from './integer-edit-field/integer-edit-field.component';
import { FloatEditFieldComponent } from './float-edit-field.component';

class OpenEditForm extends EditForm<WorkPackageResource> {
  constructor(injector:Injector, private readonly changes:ResourceChangeset<WorkPackageResource>) {
    super(injector);
    this.resource = changes.pristineResource;
  }

  override get change() { return this.changes; }
  protected activateField():Promise<EditFieldHandler> { throw new Error('Fields are already open'); }
  protected requireVisible():Promise<void> { return Promise.resolve(); }
  reset():void {}
  protected focusOnFirstError():void {}
}

function initialize(resource:HalResource):void {
  initializeHalProperties(TestBed.inject(HalResourceService), resource);
}

const fields:{ component:Type<EditFieldComponent>; value:unknown }[] = [
  { component:TextEditFieldComponent, value:'Original' },
  { component:PlainFormattableEditFieldComponent, value:{ raw:'Original' } },
  { component:BooleanEditFieldComponent, value:true },
  { component:IntegerEditFieldComponent, value:4 },
  { component:FloatEditFieldComponent, value:1.5 },
];

describe.each(fields)('$component.name submission state', ({ component, value }) => {
  async function setup() {
    const response = new Subject<WorkPackageResource>();
    const cacheUpdate = new Subject<void>();
    const cachePromise = firstValueFrom(cacheUpdate);
    let changes:ResourceChangeset<WorkPackageResource>;
    const schemaFor = vi.fn<SchemaCacheService['of']>();
    const handleRawError = vi.fn<WorkPackageNotificationService['handleRawError']>();
    const push = vi.fn<HalEventsService['push']>();
    const stopEditing = vi.fn((saved:WorkPackageResource) => { changes = new ResourceChangeset(saved); });
    const createHandler = () => {
      const injector = TestBed.inject(Injector);
      const form = new OpenEditForm(injector, changes);
      return new HalResourceEditFieldHandler(
        injector, form, 'value',
        { name:'Value', type:'String', required:false, writable:true, hasDefault:false },
        document.createElement('div'), TestBed.inject(PathHelperService), [],
      );
    };
    TestBed.configureTestingModule({
      declarations:[component, AutofocusDirective, WpCustomActionComponent],
      imports:[FormsModule, OpTooltipDirective],
      providers:[
        { provide:I18nService, useValue:{ t:(key:string) => key } },
        { provide:FocusHelperService, useValue:{ focus:vi.fn() } },
        { provide:SchemaCacheService, useValue:{ of:schemaFor } },
        { provide:HalResourceService, useValue:{ get:() => EMPTY, post:() => response } },
        { provide:HalResourceEditingService, useValue:{ changeFor:() => changes, stopEditing } },
        { provide:WorkPackageNotificationService, useValue:{ showSave:vi.fn(), handleRawError } },
        { provide:WorkPackagesActivityService, useValue:{ clear:vi.fn() } },
        { provide:HalEventsService, useValue:{ events$:EMPTY, push } },
        { provide:ApiV3Service, useValue:{ work_packages:{ id:(id:string) => ({ path:`/api/v3/work_packages/${id}` }), cache:{ updateWorkPackage:() => cachePromise } } } },
        { provide:OpEditingPortalChangesetToken, useFactory:() => changes },
        { provide:OpEditingPortalSchemaToken, useValue:{ required:false } },
        { provide:OpEditingPortalHandlerToken, useFactory:createHandler },
      ],
    });
    const injector = TestBed.inject(Injector);
    const resource = new WorkPackageResource(injector, {
      id:'1', lockVersion:1, value, _links:{ self:{ href:'/api/v3/work_packages/1' } },
    }, true, initialize, 'WorkPackage') as unknown as WorkPackageResource;
    const schema = new SchemaResource(injector, { value:{ required:false, writable:true } }, true, initialize, 'Schema');
    schemaFor.mockReturnValue(SchemaProxy.create(schema, resource));
    changes = new ResourceChangeset(resource);
    const editor = TestBed.createComponent(component);
    const action = TestBed.createComponent(WpCustomActionComponent);
    action.componentRef.setInput('workPackage', resource);
    action.componentRef.setInput('action', new CustomActionResource(injector, {
      name:'Complete', _links:{ self:{ href:'/api/v3/custom_actions/1' } },
    }, true, initialize, 'CustomAction'));
    await editor.whenStable();
    await action.whenStable();
    const input = (editor.nativeElement as HTMLElement).querySelector('input');
    const button = (action.nativeElement as HTMLElement).querySelector('button');
    if (!input || !button) throw new Error('Missing rendered controls');
    return { editor, action, input, button, changes, response, resource, cacheUpdate, cachePromise, handleRawError, stopEditing, push };
  }

  it('disables an open editor while a custom action is submitted', async () => {
    const { editor, button, input } = await setup();
    expect(input).not.toBeDisabled();
    button.click();
    await editor.whenStable();
    expect(input).toBeDisabled();
  });

  it('reenables an open editor after custom action failure', async () => {
    const { editor, button, input, response, resource, handleRawError } = await setup();
    button.click();
    await editor.whenStable();
    expect(input).toBeDisabled();
    const error = new Error('Action failed');
    response.error(error);
    await editor.whenStable();
    await expect.poll(() => input.disabled).toBe(false);
    await editor.whenStable();
    expect(button).not.toBeDisabled();
    expect(handleRawError).toHaveBeenCalledWith(error, resource);
  });

  it('reenables an open editor when the cache refresh fails', async () => {
    const { editor, button, input, response, resource, cacheUpdate, cachePromise, handleRawError } = await setup();
    button.click();
    response.next(resource);
    await Promise.resolve();
    await editor.whenStable();
    expect(input).toBeDisabled();
    const failed = cachePromise.catch(() => undefined);
    const error = new Error('Refresh failed');
    cacheUpdate.error(error);
    await failed;
    await editor.whenStable();
    await expect.poll(() => input.disabled).toBe(false);
    await editor.whenStable();
    expect(button).not.toBeDisabled();
    expect(handleRawError).toHaveBeenCalledWith(error, resource);
  });

  it('clears submission state if the action component is destroyed before failure', async () => {
    const { editor, action, button, input, response } = await setup();
    button.click();
    await editor.whenStable();
    expect(input).toBeDisabled();
    action.destroy();
    response.error(new Error('Action failed'));
    await expect.poll(() => input.disabled).toBe(false);
  });

  it('keeps editors disabled until successful cache refresh completes', async () => {
    const { editor, button, input, response, resource, cacheUpdate, cachePromise, stopEditing, push } = await setup();
    button.click();
    response.next(resource);
    await Promise.resolve();
    await editor.whenStable();
    expect(input).toBeDisabled();
    cacheUpdate.next();
    await cachePromise;
    await editor.whenStable();
    await expect.poll(() => input.disabled).toBe(false);
    await editor.whenStable();
    expect(button).not.toBeDisabled();
    expect(stopEditing).toHaveBeenCalledWith(resource);
    expect(push).toHaveBeenCalledWith(resource, { eventType:'updated' });
  });
});
