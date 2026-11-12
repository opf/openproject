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
import { TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { WpButtonMacroModalComponent } from './wp-button-macro.modal';

describe('WpButtonMacroModalComponent select events', () => {
  it('reads the selected type from the select and preserves the button-style option on submit', () => {
    const close = vi.fn();
    TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [WpButtonMacroModalComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: CurrentProjectService, useValue: { identifier: 'project' } },
        { provide: ApiV3Service, useValue: {
          withOptionalProject: () => ({ work_packages: { form: { post: () => new Subject() } } }),
        } },
        { provide: OpModalLocalsToken, useValue: { service: { close }, type: '', classes: 'button' } },
      ],
    });
    const fixture = TestBed.createComponent(WpButtonMacroModalComponent);
    fixture.detectChanges();
    const host = fixture.nativeElement as HTMLElement;
    const select = host.querySelector<HTMLSelectElement>('select')!;
    const option = document.createElement('option');
    option.value = 'Task';
    select.append(option);
    select.value = 'Task';
    select.dispatchEvent(new Event('change', { bubbles: true }));
    expect(fixture.componentInstance.selectedType).toBe('Task');
    host.querySelector<HTMLFormElement>('form')!.dispatchEvent(new Event('submit', { cancelable: true }));
    expect(fixture.componentInstance.type).toBe('Task');
    expect(fixture.componentInstance.classes).toBe('button');
    expect(fixture.componentInstance.changed).toBe(true);
    expect(close).toHaveBeenCalledExactlyOnceWith();
  });
});
