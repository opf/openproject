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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BcfPathHelperService } from 'core-app/features/bim/bcf/helper/bcf-path-helper.service';
import { BcfImportButtonComponent } from './bcf-import-button.component';

describe('BcfImportButtonComponent', () => {
  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [BcfImportButtonComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: CurrentProjectService, useValue: {} },
          { provide: BcfPathHelperService, useValue: {} },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();

    const fixture = TestBed.createComponent(BcfImportButtonComponent);
    fixture.detectChanges();
  });

  it('describes the button with its tooltip', () => {
    const button = screen.getByRole('button', { name: 'js.bcf.import' });
    const tooltip = screen.getByText('js.bcf.import_bcf_xml_file', { selector: 'tool-tip' });

    expect(button).toHaveAccessibleDescription('js.bcf.import_bcf_xml_file');
    expect(tooltip).toHaveAttribute('for', button.id);
  });
});
