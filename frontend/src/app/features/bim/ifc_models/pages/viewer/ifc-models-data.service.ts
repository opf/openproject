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

import { inject, Injectable } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { getMetaElement } from 'core-app/core/setup/globals/global-helpers';

export interface IFCPermissionMap {
  manage_ifc_models:boolean;
  manage_bcf:boolean;
}

export interface IfcProjectDefinition {
  name:string;
  id:string;
}

export interface IfcModelDefinition {
  name:string;
  id:number;
  default:boolean;
}

export interface IFCModelData {
  models:IfcModelDefinition[];
  shown_models:number[];
  projects:IfcProjectDefinition[];
  xkt_attachment_ids:Record<number, number>;
  permissions:IFCPermissionMap;
}

@Injectable()
export class IfcModelsDataService {
  private data:IFCModelData = {
    models: [],
    shown_models: [],
    projects: [],
    xkt_attachment_ids: {},
    permissions: {
      manage_ifc_models: false,
      manage_bcf: false,
    },
  };

  readonly paths = inject(PathHelperService);
  readonly currentProjectService = inject(CurrentProjectService);

  constructor() {
    const models = getMetaElement('openproject_ifc_models')?.dataset.models;
    if (models) {
      this.data = JSON.parse(models) as IFCModelData;
    }
  }

  public get models():IfcModelDefinition[] {
    return this.data.models;
  }

  public get projects():IfcProjectDefinition[] {
    return this.data.projects;
  }

  public get xktAttachmentIds():Record<number, number> {
    return this.data.xkt_attachment_ids;
  }

  public get shownModels():number[] {
    return this.data.shown_models;
  }

  public isSingleModel() {
    return this.shownModels.length === 1;
  }

  public isDefaults():boolean {
    return !this
      .models
      .find((item) => item.default && !this.shownModels.includes(item.id));
  }

  public get manageIFCPath() {
    return this.paths.ifcModelsPath(this.currentProjectService.identifier!);
  }

  public allowed(permission:keyof IFCPermissionMap):boolean {
    return !!this.data.permissions[permission];
  }
}
