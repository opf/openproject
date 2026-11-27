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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { NEVER } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { OpAttachmentListItemComponent } from './attachment-list-item.component';

describe('OpAttachmentListItemComponent', () => {
  let fixture:ComponentFixture<OpAttachmentListItemComponent>;

  const hints:Record<string, string> = {
    'js.attachments.quarantined_hint': 'This file was quarantined.',
  };

  const attachmentWithStatus = (status:string) => ({
    id: 1,
    fileName: 'report.pdf',
    contentType: 'application/pdf',
    status,
    createdAt: '2026-11-27T10:00:00Z',
    _links: {
      author: { href: '/api/v3/users/1' },
      staticDownloadLocation: { href: '/attachments/1/report.pdf' },
    },
  }) as unknown as IAttachment;

  const render = (status:string) => {
    fixture = TestBed.createComponent(OpAttachmentListItemComponent);
    fixture.componentInstance.attachment = attachmentWithStatus(status);
    fixture.detectChanges();
  };

  const host = () => fixture.nativeElement as HTMLElement;
  const link = () => host().querySelector<HTMLAnchorElement>('a.op-file-list--item-action')!;

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [OpAttachmentListItemComponent],
        imports: [OpTooltipDirective],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => hints[key] ?? key } },
          { provide: PathHelperService, useValue: {} },
          { provide: TimezoneService, useValue: { parseDatetime: () => ({ fromNow: () => 'today' }) } },
          { provide: ConfirmDialogService, useValue: {} },
          { provide: PrincipalsResourceService, useValue: { requireEntity: () => NEVER } },
          { provide: PrincipalRendererService, useValue: { render: () => undefined } },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();
  });

  it('describes a quarantined attachment by a tooltip on its link', () => {
    render('quarantined');

    const tooltip = host().querySelector<HTMLElement>('tool-tip')!;
    expect(tooltip.textContent).toEqual('This file was quarantined.');
    expect(tooltip.dataset.type).toEqual('description');
    expect(link().getAttribute('aria-describedby')).toContain(tooltip.id);
  });

  it('shows no tooltip for an uploaded attachment', () => {
    render('uploaded');

    expect(host().querySelector('tool-tip')).toBeNull();
  });
});
