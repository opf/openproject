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
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit,
  forwardRef,
  EventEmitter,
  Output,
  HostBinding,
  ViewEncapsulation,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ID } from '@datorama/akita';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3ListFilter, listParamsString } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IProject } from 'core-app/core/state/projects/project.model';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

import { IProjectAutocompleteItem } from './project-autocomplete-item';
import { buildTree } from './insert-in-list';
import { recursiveSort } from './recursive-sort';
import { flattenProjectTree } from './flatten-project-tree';

export const projectsAutocompleterSelector = 'op-project-autocompleter';

export interface IProjectAutocompleterData {
  id:ID;
  href:string;
  name:string;
};

@Component({
  templateUrl: './project-autocompleter.component.html',
  styleUrls: ['./project-autocompleter.component.sass'],
  encapsulation: ViewEncapsulation.None,
  selector: projectsAutocompleterSelector,
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => ProjectAutocompleterComponent),
    multi: true,
  }],
})
export class ProjectAutocompleterComponent implements OnInit, ControlValueAccessor {
  @HostBinding('class.op-project-autocompleter') public className = true;

  projectTracker = (item:IProjectAutocompleteItem) => {
    return item.href || item.id;
  }

  // Load all projects as default
  @Input() public url:string = this.apiV3Service.projects.path;

  @Input() public name = '';

  @Input() public focusDirectly = false;

  @Input() public multiple = false;

  @Input() public APIFilters:ApiV3ListFilter[] = [];

  // This function allows mapping of the results before they are fed to the tree
  // structuring and destructuring algorithms used internally the this component
  // to show the tree structure. By default it does not do much, but it is
  // overwritable so additional filtering or transforming can be done on the
  // API result set.
  @Input()
  public mapResultsFn:(projects:IProjectAutocompleteItem[]) => IProjectAutocompleteItem[] = (projects) => projects;

  @Input('value') public _value:IProjectAutocompleterData|null = null;

  get value():IProjectAutocompleterData|null {
    return this._value;
  }

  set value(value:IProjectAutocompleterData|null) {
    this._value = value;
    this.onChange(value);
    this.changeEmitter.emit(value);
    this.onTouched(value);
  }

  @Output('change') changeEmitter = new EventEmitter<IProjectAutocompleterData|null>();

  constructor(
    public elementRef:ElementRef,
    protected halResourceService:HalResourceService,
    protected I18n:I18nService,
    protected halNotification:HalResourceNotificationService,
    readonly http:HttpClient,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly injector:Injector,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit() { }

  public getAvailableProjects(searchTerm:string):Observable<IProjectAutocompleteItem[]> {
    return getPaginatedResults<IProject>(
      (params) => {
        const filters:ApiV3ListFilter[] = [...this.APIFilters];
        
        if (searchTerm.length) {
          filters.push(['name_and_identifier', '~', [searchTerm]]);
        }
        const fullParams = {
          filters,
          select: [
            'elements/id',
            'elements/name',
            'elements/identifier',
            'elements/self',
            'elements/ancestors',
            'total',
            'count',
            'pageSize',
          ],
          ...params,
        };
        const collectionURL = listParamsString(fullParams);
        return this.http.get<IHALCollection<IProject>>(this.url + collectionURL);
      },
    )
      .pipe(
        map((projects) => projects.map((project) => ({
          id: project.id,
          href: project._links.self.href,
          name: project.name,
          disabled: false,
          ancestors: project._links.ancestors,
          children: [],
        }))),
        map(this.mapResultsFn),
        map((projects) => projects.sort((a, b) => a.ancestors.length - b.ancestors.length)),
        map((projects) => buildTree(projects)),
        map((projects) => recursiveSort(projects)),
        map((projectTreeItems) => flattenProjectTree(projectTreeItems)),
      );
  }

  writeValue(value:IProjectAutocompleterData|null) {
    this.value = value;
  }

  onChange = (_:IProjectAutocompleterData|null):void => {};

  onTouched = (_:IProjectAutocompleterData|null):void => {};

  registerOnChange(fn:(_:IProjectAutocompleterData|null) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:IProjectAutocompleterData|null) => void):void {
    this.onTouched = fn;
  }
}
