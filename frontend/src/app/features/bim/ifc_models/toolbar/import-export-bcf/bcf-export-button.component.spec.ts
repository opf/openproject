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
import { HttpClient } from '@angular/common/http';
import { of } from 'rxjs';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BcfPathHelperService } from 'core-app/features/bim/bcf/helper/bcf-path-helper.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { JobStatusModalService } from 'core-app/features/job-status/job-status-modal.service';
import { BcfExportButtonComponent } from './bcf-export-button.component';

describe('BcfExportButtonComponent', () => {
  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [BcfExportButtonComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: CurrentProjectService, useValue: { identifier: 'demo' } },
          { provide: BcfPathHelperService, useValue: { projectExportIssuesPath: () => '/bcf/export' } },
          { provide: IsolatedQuerySpace, useValue: { query: { values$: () => of({ filters: [] }) } } },
          { provide: UrlParamsHelperService, useValue: { buildV3GetFilters: () => [] } },
          { provide: JobStatusModalService, useValue: {} },
          { provide: HttpClient, useValue: {} },
          { provide: ToastService, useValue: {} },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();

    const fixture = TestBed.createComponent(BcfExportButtonComponent);
    fixture.detectChanges();
  });

  it('describes the link with its tooltip', () => {
    const link = screen.getByRole('link', { name: 'js.bcf.export' });
    const tooltip = screen.getByText('js.bcf.export_bcf_xml_file', { selector: 'tool-tip' });

    expect(link).toHaveAccessibleDescription('js.bcf.export_bcf_xml_file');
    expect(tooltip).toHaveAttribute('for', link.id);
  });
});
