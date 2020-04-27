// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {AfterViewInit, Directive, ElementRef, Injector} from '@angular/core';
import {takeUntil} from 'rxjs/operators';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {States} from '../../states.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {QueryColumn} from "core-components/wp-query/query-column";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {WorkPackageViewSumService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sum.service";
import {combineLatest} from "rxjs";

@Directive({
  selector: '[wpTableSumsRow]'
})
export class WorkPackageTableSumsRowController implements AfterViewInit {

  private text:{ sum:string };

  private $element:JQuery;

  constructor(readonly injector:Injector,
              readonly elementRef:ElementRef,
              readonly querySpace:IsolatedQuerySpace,
              readonly states:States,
              readonly displayFieldService:DisplayFieldService,
              readonly wpTableColumns:WorkPackageViewColumnsService,
              readonly wpTableSums:WorkPackageViewSumService,
              readonly I18n:I18nService) {

    this.text = {
      sum: I18n.t('js.label_sum')
    };
  }

  ngAfterViewInit():void {
    this.$element = jQuery(this.elementRef.nativeElement);

    combineLatest([
      this.wpTableColumns.live$(),
      this.wpTableSums.live$(),
      this.querySpace.results.values$(),
    ])
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe(([columns, sum, resource]) => {
        if (sum && resource.sumsSchema) {
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

  private refresh(columns:QueryColumn[], resource:WorkPackageCollectionResource, schema:SchemaResource) {
    this.clear();
    this.render(columns, resource, schema);
  }

  private render(columns:QueryColumn[], resource:WorkPackageCollectionResource, schema:SchemaResource) {
    // build
    columns.forEach((column, i:number) => {
      const td = document.createElement('td');
      td.classList.add('wp-table--sum-container');
      const div = this.renderContent(resource.totalSums!, column.id, schema[column.id]);

      if (i === 0) {
        this.appendFirstLabel(div);
        // colspan 2 for the d&d column
        td.setAttribute('colspan', '2');
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

    const field = this.displayFieldService.getField(
      sums,
      name,
      fieldSchema,
      { injector: this.injector, container: 'table', options: {} }
      );

    if (!field.isEmpty()) {
      field.render(div, field.valueString);
    }

    return div;
  }

  private appendFirstLabel(div:HTMLElement) {
    const span = document.createElement('span');
    span.textContent = `${this.text.sum}`;
    jQuery(div).prepend(span);
  }
}
