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

import {wpButtonsModule} from '../../../angular-modules';

export default class WorkPackageCreateButtonController {
  public projectIdentifier: string;
  public text: any;
  public types: any;

  protected canCreate: boolean = false;

  // All available projects outside project context
  protected availableProjects = [];

  // Template create form
  protected form: op.HalResource;

  public get inProjectContext() {
    return !!this.projectIdentifier;
  }

  constructor(
    protected $state,
    protected I18n,
    protected ProjectService,
    protected apiWorkPackages
  ) {
    this.text = {
      button: I18n.t('js.label_work_package'),
      create: I18n.t('js.label_create_work_package')
    };

    this.setupProject().then(identifier => {
      apiWorkPackages.emptyCreateForm(identifier).then(resource => {
        this.form = resource;
        this.types = resource.schema.type.allowedValues;
      });
    });
  }

  public isDisabled() {
    return!this.canCreate || this.$state.includes('**.new') || !this.types;
  }

  public get firstAvailableProject() {
    if (this.inProjectContext) {
      return this.projectIdentifier;
    } else {
      return this.availableProjects[0].identifier;
    }
  }

  private setupProject() {
    if (this.inProjectContext) {
      return this.ProjectService.fetchProjectResource(this.projectIdentifier).then(project => {
        this.canCreate = !!project.createWorkPackage;
        return this.projectIdentifier;
      });
    } else {
      return this.apiWorkPackages.availableProjects().then(resource => {
        this.canCreate = (resource && resource.total > 0);
        this.availableProjects = resource.elements;
        if (this.canCreate) {
          return this.firstAvailableProject;
        }
      });
    }
  }
}

wpButtonsModule.controller('WorkPackageCreateButtonController', WorkPackageCreateButtonController);
