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

import {AfterViewInit, Component, EventEmitter, OnInit, Output, ViewChild} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {VersionDmService} from "core-app/modules/hal/dm-services/version-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {VersionResource} from "core-app/modules/hal/resources/version-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";

@Component({
  template: `
    <create-autocompleter #createAutocompleter
                          [availableValues]="availableValues"
                          [createAllowed]="createAllowed"
                          [finishedLoading]="loaded"
                          [appendTo]="appendTo"
                          [model]="model"
                          [required]="required"
                          [disabled]="disabled"
                          [id]="id"
                          [classes]="classes"
                          (create)="createNewVersion($event)"
                          (onChange)="changeModel($event)"
                          (onOpen)="opened()"
                          (onClose)="closed()"
                          (onKeydown)="keyPressed($event)"
                          (onAfterViewInit)="afterViewinited()">
    </create-autocompleter>
  `,
  selector: 'version-autocompleter'
})

export class VersionAutocompleterComponent extends CreateAutocompleterComponent implements OnInit, AfterViewInit {
  @ViewChild('createAutocompleter', { static: true }) public createAutocompleter:CreateAutocompleterComponent;
  @Output() public onCreate = new EventEmitter<VersionResource>();

  public createAllowed:boolean = false;
  public loaded:boolean = false;

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly pathHelper:PathHelperService,
              readonly versionDm:VersionDmService,
              readonly wpNotifications:WorkPackageNotificationService) {
    super(I18n, currentProject, pathHelper);
  }

  ngOnInit() {
    this.canCreateNewActionElements().then((val) => {
      this.loaded = true;
      this.createAutocompleter.createAllowed = val;
    });
  }

  ngAfterViewInit() {
    // Prevent a second event to bubble
  }

  public afterViewinited() {
    this.onAfterViewInit.emit(this.createAutocompleter);
  }

  /**
   * Checks for correct permissions
   * (whether the current project is in the list of allowed values in the version create form)
   * @returns {Promise<boolean>}
   */
  public canCreateNewActionElements():Promise<boolean> {
    let that = this;
    return this.versionDm.listProjectsAvailableForVersions().then((collection) => {
      return collection.elements.some((e:HalResource) => e.id === that.currentProject.id!);
    }).catch(() => {
      return false;
    });
  }

  public createNewVersion(name:string) {
    this.versionDm.createVersion(this.getVersionPayload(name))
      .then((version) => {
        this.onCreate.emit(version);
      })
      .catch(error =>  {
        this.createAutocompleter.closeSelect();
        this.wpNotifications.handleRawError(error);
      });
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
