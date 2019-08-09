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

import {Component, OnInit, ChangeDetectionStrategy, ChangeDetectorRef, Injector, ViewChild, ElementRef} from '@angular/core';
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ProjectDmService} from "core-app/modules/hal/dm-services/project-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {DisplayFieldContext, DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";
import {PortalCleanupService} from 'core-app/modules/fields/display/display-portal/portal-cleanup.service';
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";

export const emptyPlaceholder = '-';

@Component({
  templateUrl: './project-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    // required by the displayField service to render the fields
    PortalCleanupService,
    WorkPackageTableHighlightingService,
    IsolatedQuerySpace
  ]
})
export class WidgetProjectDetailsComponent extends AbstractWidgetComponent implements OnInit {
  public customFieldsMap:Array<DisplayField> = [];

  @ViewChild('contentContainer', { static: true }) readonly contentContainer:ElementRef;

  constructor(protected readonly i18n:I18nService,
              protected readonly injector:Injector,
              protected readonly projectDm:ProjectDmService,
              protected readonly currentProject:CurrentProjectService,
              protected readonly displayField:DisplayFieldService,
              protected readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.loadAndRender();
  }

  private loadAndRender() {
    Promise.all(
        [this.loadCurrentProject(),
        this.loadProjectSchema()]
      )
      .then(([project, schema]) => {
        this.renderCFs(project, schema as SchemaResource);

        this.redraw();
      });
  }

  private loadCurrentProject() {
    return this.projectDm.load(this.currentProject.id as string);
  }

  private loadProjectSchema() {
    return this.projectDm.schema();
  }

  private renderCFs(project:ProjectResource, schema:SchemaResource) {
    const cfFields = this.collectFieldsForCfs(project, schema);

    this.sortFieldsLexicographically(cfFields);
    this.renderFields(cfFields);
  }

  private collectFieldsForCfs(project:ProjectResource, schema:SchemaResource) {
    let displayFields:Array<DisplayField> = [];
    // passing an arbitrary context to displayField.getField only to satisfy the interface
    let context:DisplayFieldContext = {injector: this.injector, container: 'table', options: []};

    Object.entries(schema).forEach(([key, keySchema]) => {
      if (key.match(/customField\d+/)) {
        let field = this.displayField.getField(project, key, keySchema, context);

        displayFields.push(field);
      }
    });

    return displayFields;
  }

  private sortFieldsLexicographically(fields:Array<DisplayField>) {
    fields.sort((a, b) => { return a.label.localeCompare(b.label); });
  }

  private renderFields(fields:Array<DisplayField>) {
    this.contentContainer.nativeElement.innerHTML = '';

    fields.forEach(field => {
      this.contentContainer.nativeElement.appendChild(this.displayKeyValue(field));
    });
  }

  private displayKeyValue(field:DisplayField) {
    const container = this.containerElement();

    container.appendChild(this.labelElement(field));
    container.appendChild(this.valueElement(field));

    return container;
  }

  private containerElement() {
    const container = document.createElement('div');
    container.classList.add('attributes-key-value');

    return container;
  }

  private labelElement(field:DisplayField) {
    const label = document.createElement('div');
    label.classList.add('attributes-key-value--key');
    label.innerText = field.label;

    return label;
  }

  private valueElement(field:DisplayField) {
    const value = document.createElement('div');
    value.classList.add('attributes-key-value--value-container');
    field.render(value, this.getText(field));

    return value;
  }

  private getText(field:DisplayField):string {
    if (field.isEmpty()) {
      return emptyPlaceholder;
    } else {
      return field.valueString;
    }
  }

  private redraw() {
    this.cdr.detectChanges();
  }
}
