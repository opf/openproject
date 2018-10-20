// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {AfterViewInit, Directive, ElementRef, Inject, Injector} from '@angular/core';
import {combine} from 'reactivestates';
import {takeUntil} from 'rxjs/operators';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {States} from '../../states.service';
import {WorkPackageTableColumns} from '../../wp-fast-table/wp-table-columns';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {IFieldSchema} from "core-app/modules/fields/field.base";

@Directive({
  selector: '[wpTableSumsRow]'
})
export class WorkPackageTableSumsRowController implements AfterViewInit {

  private text:{ sumFor:string, allWorkPackages:string };

  private $element:JQuery;

  constructor(public readonly injector:Injector,
              public readonly elementRef:ElementRef,
              public readonly tableState:TableState,
              private states:States,
              private displayFieldService:DisplayFieldService,
              readonly I18n:I18nService) {

    this.text = {
      sumFor: I18n.t('js.label_sum_for'),
      allWorkPackages: I18n.t('js.label_all_work_packages')
    };
  }

  ngAfterViewInit():void {
    this.$element = jQuery(this.elementRef.nativeElement);

    combine(
      this.tableState.columns,
      this.tableState.results,
      this.tableState.sum
    )
      .values$()
      .pipe(
        takeUntil(this.tableState.stopAllSubscriptions)
      )
      .subscribe(([columns, resource, sum]) => {
        if (sum.isEnabled && resource.sumsSchema) {
          resource.sumsSchema.$load().then((schema:SchemaResource) => {
            this.refresh(columns, resource, schema);
          });
        } else {
          this.clear();
        }
      });
  }

  private clear() {
    this.$element.empty();
  }

  private refresh(columns:WorkPackageTableColumns, resource:WorkPackageCollectionResource, schema:SchemaResource) {
    this.clear();
    this.render(columns, resource, schema);
  }

  private render(columns:WorkPackageTableColumns, resource:WorkPackageCollectionResource, schema:SchemaResource) {
    this.elementRef.nativeElement.classList.add('sum', 'group', 'all', 'issue', 'work_package');

    // build
    columns.getColumns().forEach((column, i:number) => {
      const td = document.createElement('td');
      const div = this.renderContent(resource.totalSums!, column.id, schema[column.id]);

      if (i === 0) {
        this.appendFirstLabel(div);
      }

      td.appendChild(div);
      this.$element.append(td);
    });

    // Append last empty td
    this.$element.append(`<td><div class="generic-table--footer-outer"></div></td>`);
  }

  private renderContent(sums:any, name:string, fieldSchema:IFieldSchema) {
    const div = document.createElement('div');

    // The field schema for this element may be undefined
    // because it is not summable.
    if (!fieldSchema) {
      return div;
    }

    const field = this.displayFieldService.getField(sums, name, fieldSchema, { container: 'table', options: {} });

    if (!field.isEmpty()) {
      field.render(div, field.valueString);
    }

    return div;
  }

  private appendFirstLabel(div:HTMLElement) {
    const span = document.createElement('span');
    span.textContent = `${this.text.sumFor} ${this.text.allWorkPackages}`;
    jQuery(div).prepend(span);
  }
}
