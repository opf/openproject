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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ExternalQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.service';

@Component({
  selector: 'opce-editable-query-props',
  templateUrl: './editable-query-props.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class EditableQueryPropsComponent implements OnInit {
  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private I18n = inject(I18nService);
  private cdRef = inject(ChangeDetectorRef);
  private externalQuery = inject(ExternalQueryConfigurationService);

  id:string|null;

  name:string|null;

  urlParams = false;

  queryProps:string;

  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query'),
  };

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.id = element.dataset.id!;
    this.name = element.dataset.name!;
    this.urlParams = element.dataset.urlParams === 'true';

    this.queryProps = element.dataset.query!;
  }

  public editQuery() {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const queryProperties = (() => {
      if (this.urlParams) {
        return this.queryProps;
      }

      try {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-return
        return JSON.parse(this.queryProps);
      } catch (e) {
        console.error(`Failed to parse query props from ${this.queryProps}: ${e}`);
        return {};
      }
    })();

    this.externalQuery.show({

      currentQuery: queryProperties,
      urlParams: this.urlParams,
      callback: (queryProps:string) => {
        this.queryProps = this.urlParams ? queryProps : JSON.stringify(queryProps);
        this.cdRef.detectChanges();
      },
    });
  }
}
