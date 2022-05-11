// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  Component, ElementRef, EventEmitter, Injector, Input, OnInit, Output, ViewChild,
} from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  DebouncedRequestSwitchmap,
  errorNotificationHandler,
} from 'core-app/shared/helpers/rxjs/debounced-input-switchmap';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder, FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { DatasetInputs } from 'core-app/shared/components/dataset-inputs.decorator';

export const projectsAutocompleterSelector = 'op-project-autocompleter';

export interface IProjectAutocompleteItem {
  name:string;
  id:string|null;
  href:string|null;
  avatar:string|null;
}

export interface IProjectAutocompleterFilters {
  selector:string;
  operator:FilterOperator;
  values:string[];
};

@DatasetInputs
@Component({
  templateUrl: './project-autocompleter.component.html',
  selector: projectsAutocompleterSelector,
})
export class ProjectAutocompleterComponent implements OnInit {
  projectTracker = (item:any) => item.href || item.id;

  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  @Output() public onChange = new EventEmitter<IProjectAutocompleteItem>();

  @Input() public clearAfterSelection = false;

  // Load all projects as default
  @Input() public url:string = this.apiV3Service.projects.path;

  @Input() public allowEmpty = false;

  @Input() public appendTo = '';

  @Input() public multiple = false;

  @Input() public initialSelection:number|null = null;

  private _additionalFilters:IProjectAutocompleterFilters[] = [];
  @Input()
  public set additionalFilters(newFilters:IProjectAutocompleterFilters[]) {
    this._additionalFilters = newFilters;
    this.inputFilters = new ApiV3FilterBuilder();
    this.additionalFilters.forEach((filter) => this.inputFilters.add(filter.selector, filter.operator, filter.values));
  }
  public get additionalFilters() {
    return this._additionalFilters;
  }

  public inputFilters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

  // Update an input field after changing, used when externally loaded
  private updateInputField:HTMLInputElement|undefined;

  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, IProjectAutocompleteItem>(
    (searchTerm:string) => this.getAvailableProjects(this.url, searchTerm),
    errorNotificationHandler(this.halNotification),
  );


  constructor(
    public elementRef:ElementRef,
    protected halResourceService:HalResourceService,
    protected I18n:I18nService,
    protected halNotification:HalResourceNotificationService,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly injector:Injector,
  ) { }

  ngOnInit() { }

  public onFocus() {
    if (!this.requests.lastRequestedValue) {
      this.requests.input$.next('');
    }
  }

  public onModelChange(project:any) {
    if (project) {
      this.onChange.emit(project);
      this.requests.input$.next('');

      if (this.clearAfterSelection) {
        this.ngSelectComponent.clearItem(project);
      }

      if (this.updateInputField) {
        if (this.multiple) {
          this.updateInputField.value = project.map((u:ProjectResource) => u.id);
        } else {
          this.updateInputField.value = project.id;
        }
      }
    }
  }

  protected getAvailableProjects(url:string, searchTerm:any):Observable<IProjectAutocompleteItem[]> {
    // Need to clone the filters to not add additional filters on every
    // search term being processed.
    const searchFilters = this.inputFilters.clone();

    if (searchTerm && searchTerm.length) {
      searchFilters.add('name', '~', [searchTerm]);
    }

    return this.halResourceService
      .get(url, { filters: searchFilters.toJson() })
      .pipe(
        map((res) => {
          const options = res.elements.map((el:any) => ({
            name: el.name, id: el.id, href: el.href, avatar: el.avatar,
          }));

          if (this.allowEmpty) {
            options.unshift({ name: this.I18n.t('js.timelines.filter.noneSelection'), href: null, id: null });
          }

          return options;
        }),
      );
  }

  private setInitialSelection() {
    if (this.updateInputField) {
      const id = parseInt(this.updateInputField.value);
      this.initialSelection = isNaN(id) ? null : id;
    }
  }
}
