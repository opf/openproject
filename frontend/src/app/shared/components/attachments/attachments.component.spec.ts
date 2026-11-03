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

import { CommonModule } from '@angular/common';
import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { Subject } from 'rxjs';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { OpAttachmentsComponent } from './attachments.component';

@Component({
  selector: 'op-attachment-list',
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class AttachmentListStubComponent {
  @Input() attachments:IAttachment[];
  @Input() collectionKey:string;
  @Input() showTimestamp:boolean;
  @Input() showDelete:boolean;
}

describe('attachment rendering states', () => {
  it('preserves pending, empty and populated collections', () => {
    TestBed.configureTestingModule({
      declarations: [OpAttachmentsComponent],
      imports: [CommonModule, AttachmentListStubComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        ...[States, HalResourceService, AttachmentsResourceService, ToastService, OpUploadService, TimezoneService]
          .map((provide) => ({ provide, useValue: {} })),
      ],
    });
    vi.spyOn(OpAttachmentsComponent.prototype, 'ngOnInit').mockImplementation(() => undefined);
    vi.spyOn(OpAttachmentsComponent.prototype, 'collectionKey', 'get').mockReturnValue('new');
    const fixture = TestBed.createComponent(OpAttachmentsComponent);
    const resource = Object.create(HalResource.prototype) as HalResource;
    Object.defineProperty(resource, 'canAddAttachments', { value: true });
    fixture.componentRef.setInput('resource', resource);
    const attachments = new Subject<IAttachment[]>();
    fixture.componentInstance.attachments$ = attachments;
    const host = fixture.nativeElement as HTMLElement;

    fixture.detectChanges();
    expect(host.querySelector('op-attachment-list')).toBeNull();
    expect(host.textContent).toContain('js.label_drop_files');

    attachments.next([]);
    fixture.detectChanges();
    expect(host.querySelector('op-attachment-list')).toBeNull();
    expect(host.textContent).toContain('js.label_drop_or_click_files');

    const populated = [{} as IAttachment];
    attachments.next(populated);
    fixture.detectChanges();
    const list = fixture.debugElement.query(By.directive(AttachmentListStubComponent)).componentInstance as AttachmentListStubComponent;
    expect(list.attachments).toBe(populated);
    expect(host.textContent).toContain('js.label_drop_files');
    fixture.destroy();
    expect(attachments.observed).toBe(false);
  });
});
