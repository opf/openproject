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

import { OpenprojectGridsModule } from 'core-app/shared/components/grids/openproject-grids.module';
import { CommonModule } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed, ComponentFixture } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { of } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { GridRemoveWidgetService } from 'core-app/shared/components/grids/grid/remove-widget.service';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpAttachmentListComponent } from 'core-app/shared/components/attachments/attachment-list/attachment-list.component';
import { OpAttachmentListItemComponent } from 'core-app/shared/components/attachments/attachment-list/attachment-list-item.component';
import { OpAttachmentsComponent } from 'core-app/shared/components/attachments/attachments.component';
import { EditFormPortalComponent } from 'core-app/shared/components/fields/edit/editing-portal/edit-form-portal.component';
import { EditFieldService } from 'core-app/shared/components/fields/edit/edit-field.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WidgetHeaderComponent } from '../header/header.component';
import { WidgetMenuComponent } from '../menu/widget-menu.component';
import { WidgetCustomTextComponent } from './custom-text.component';

describe('WidgetCustomTextComponent editing attachments', () => {
  let fixture:ComponentFixture<WidgetCustomTextComponent>;
  let grid:GridResource;
  const attachFiles = vi.fn(() => of(undefined));

  beforeEach(async () => {
    attachFiles.mockClear();
    TestBed.overrideModule(OpenprojectGridsModule, {
      set: {
        imports: [CommonModule, IconModule],
        declarations: [WidgetCustomTextComponent, WidgetHeaderComponent, WidgetMenuComponent, EditFormPortalComponent, OpAttachmentsComponent, OpAttachmentListComponent, OpAttachmentListItemComponent],
        exports: [WidgetCustomTextComponent], providers: [], schemas: [],
      },
    });
    TestBed.configureTestingModule({
      imports: [OpenprojectGridsModule],
      providers: [
        provideHttpClient(), provideHttpClientTesting(), States, SchemaCacheService,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: TimezoneService, useValue: {} },
        { provide: GridAreaService, useValue: { isEditable: true } },
        { provide: GridDragAndDropService, useValue: {} },
        { provide: GridRemoveWidgetService, useValue: {} },
        { provide: EditFieldService, useValue: { getSpecificClassFor: () => undefined } },
        { provide: OpUploadService, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: AttachmentsResourceService, useValue: { requireCollection: () => of([]), collection: () => of([]), attachFiles } },
      ],
    });
    TestBed.overrideTemplate(WidgetHeaderComponent, '');
    TestBed.overrideTemplate(WidgetMenuComponent, '');
    await TestBed.compileComponents();
    const factory = TestBed.inject(HalResourceService);
    factory.registerResource('Grid', { cls: GridResource });
    factory.registerResource('GridWidget', { cls: GridWidgetResource });
    grid = factory.createHalResourceOfType<GridResource>('Grid', {
      id: 1, widgets: [], _links: {
        self: { href: '/api/v3/grids/1' }, attachments: { href: '/api/v3/grids/1/attachments' },
        addAttachment: { href: '/api/v3/grids/1/attachments', method: 'post' },
      },
    }, true);
    const widget = factory.createHalResourceOfType<GridWidgetResource>('GridWidget', {
      id: 1, options: { text: { raw: 'Original', html: '<p>Original</p>' } },
    }, true);
    widget.grid = grid;
    fixture = TestBed.createComponent(WidgetCustomTextComponent);
    fixture.componentRef.setInput('resource', widget);
    fixture.detectChanges();
  });

  async function activate() {
    const update = vi.spyOn(grid, 'updateAttachments').mockResolvedValue(grid);
    fixture.nativeElement.querySelector('button').click();
    await Promise.resolve();
    fixture.detectChanges();
    return update;
  }

  it('uses the translated attachment legend while editing', async () => {
    const update = await activate();
    expect(update).toHaveBeenCalledOnce();
    expect(fixture.nativeElement.querySelector('legend')).toHaveTextContent('js.label_attachments');
  });

  it('uploads to the grid and waits for editor submit callbacks before saving', async () => {
    await activate();
    const attachments = fixture.debugElement.query(By.directive(OpAttachmentsComponent)).componentInstance as OpAttachmentsComponent;
    expect(attachments.resource).toBe(grid);
    const files = new DataTransfer();
    const file = new File(['Attachment'], 'notes.txt', { type: 'text/plain' });
    files.items.add(file);
    attachments.filePicker.nativeElement.files = files.files;
    attachments.filePicker.nativeElement.dispatchEvent(new Event('change'));
    expect(attachFiles).toHaveBeenCalledWith(grid, [file]);
    const component = fixture.componentInstance;
    const changed = vi.spyOn(component.resourceChanged, 'emit');
    let finish!:() => void;
    component.handler.registerOnSubmit(() => new Promise<void>((resolve) => { finish = resolve; }));
    component.handler.changeset.setValue('text', { raw: 'Saved text' });
    const save = component.handler.handleUserSubmit();
    expect(component.active).toBe(true);
    expect(changed).not.toHaveBeenCalled();
    finish();
    await save;
    expect(changed).toHaveBeenCalledOnce();
    expect(component.active).toBe(false);
  });

  it('cancels without emitting a resource change', async () => {
    await activate();
    const changed = vi.spyOn(fixture.componentInstance.resourceChanged, 'emit');
    fixture.componentInstance.handler.changeset.setValue('text', { raw: 'Discard' });
    fixture.componentInstance.handler.handleUserCancel();
    fixture.changeDetectorRef.markForCheck();
    fixture.detectChanges();
    expect(fixture.componentInstance.active).toBe(false);
    expect(changed).not.toHaveBeenCalled();
    expect(fixture.nativeElement.querySelector('fieldset')).toBeNull();
  });
});
