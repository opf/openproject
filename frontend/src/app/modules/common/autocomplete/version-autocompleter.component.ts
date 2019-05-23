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

import {Component, EventEmitter, Input, OnInit, Output} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {VersionDmService} from "core-app/modules/hal/dm-services/version-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {VersionResource} from "core-app/modules/hal/resources/version-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Component({
  template: `
    <create-autocompleter [availableValues]="availableValues"
                          [createAllowed]="createAllowed"
                          [appendTo]="'body'"
                          [model]=""
                          (onCreate)="createNewVersion($event)"
                          (onChange)="onModelChanged($event)">
    </create-autocompleter>
  `,
  selector: 'version-autocompleter'
})

export class VersionAutocompleterComponent implements OnInit {
  @Input() public availableValues:any[];
  @Input() public createAllowed:boolean;

  @Output() public onCreate = new EventEmitter<VersionResource>();
  @Output() public onChange = new EventEmitter<VersionResource>();

  constructor(readonly currentProject:CurrentProjectService,
              readonly pathHelper:PathHelperService,
              readonly versionDm:VersionDmService) {
  }

  ngOnInit() {
    this.canCreateNewActionElements().then((val) => {
      this.createAllowed = val;
    });
  }

  /**
   * Checks for correct permissions
   * (whether the current project is in the list of allowed values in the version create form)
   * @returns {Promise<boolean>}
   */
  public canCreateNewActionElements():Promise<boolean> {
    var that = this;
    return this.versionDm.emptyCreateForm(this.getVersionPayload('')).then((form) => {
      return form.schema.definingProject.allowedValues.some((e:HalResource) => e.id === that.currentProject.id!);
    });
  }

  public createNewVersion(name:string) {
    this.versionDm.createVersion(this.getVersionPayload(name)).then((version) => {
      this.onCreate.emit(version);
    });
  }

  public onModelChanged(element:VersionResource) {
    this.onChange.emit(element);
  }

  private getVersionPayload(name:string) {
    let payload:any = {};
    payload['name'] = name;
    payload['_links'] = {
      definingProject: {
        href: this.pathHelper.api.v3.projects.id(this.currentProject.id!).path
      }
    };

    return payload;
  }
}

DynamicBootstrapper.register({ selector: 'version-autocompleter', cls: VersionAutocompleterComponent  });
