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

import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { DisplayFieldContextOptions } from '../display-field.service';
import { HighlightableDisplayField } from './highlightable-display-field.module';
import { TypeDisplayField } from './type-display-field.module';

class StatusOnlyDisplayField extends HighlightableDisplayField {
  public override get shouldHighlight():boolean {
    return super.shouldHighlight && this.name === 'status';
  }
}

describe('highlightable table fields', () => {
  const service = { shouldHighlightInline: vi.fn() };

  beforeEach(() => {
    service.shouldHighlightInline.mockReset();
    TestBed.configureTestingModule({
      providers: [
        { provide: WorkPackageViewHighlightingService, useValue: service },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });
  });

  const context = (options:DisplayFieldContextOptions) => ({
    injector: TestBed.inject(Injector),
    container: 'table' as const,
    options,
  });

  it('asks the template selection for the mapped highlight name', () => {
    const shouldHighlightInline = vi.fn((name:string) => name === 'dueDate');
    const options = context({ shouldHighlightInline });

    expect(new HighlightableDisplayField('date', options).shouldHighlight).toBe(true);
    expect(new HighlightableDisplayField('status', options).shouldHighlight).toBe(false);
    expect(shouldHighlightInline.mock.calls).toEqual([['dueDate'], ['status']]);
    expect(service.shouldHighlightInline).not.toHaveBeenCalled();
  });

  it('respects a field override that also calls the base getter', () => {
    const shouldHighlightInline = vi.fn(() => true);
    const options = context({ shouldHighlightInline });

    expect(new StatusOnlyDisplayField('status', options).shouldHighlight).toBe(true);
    expect(new StatusOnlyDisplayField('priority', options).shouldHighlight).toBe(false);
    expect(shouldHighlightInline.mock.calls).toEqual([['status'], ['priority']]);
  });

  it('keeps Type highlighted independently of the selected fields', () => {
    const shouldHighlightInline = vi.fn(() => false);
    expect(new TypeDisplayField('type', context({ shouldHighlightInline })).shouldHighlight).toBe(true);
    expect(shouldHighlightInline).not.toHaveBeenCalled();
  });

  it('honors colorize false before asking either table selection', () => {
    const shouldHighlightInline = vi.fn(() => true);
    expect(new HighlightableDisplayField('status', context({ colorize: false, shouldHighlightInline })).shouldHighlight).toBe(false);
    expect(shouldHighlightInline).not.toHaveBeenCalled();
    expect(service.shouldHighlightInline).not.toHaveBeenCalled();
  });

  it('uses the service when no template selection is provided', () => {
    service.shouldHighlightInline.mockReturnValue(true);
    expect(new HighlightableDisplayField('date', context({})).shouldHighlight).toBe(true);
    expect(service.shouldHighlightInline).toHaveBeenCalledWith('dueDate');
  });
});
