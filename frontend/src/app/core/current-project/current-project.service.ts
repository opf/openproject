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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { getMetaElement } from '../setup/globals/global-helpers';

@Injectable({ providedIn: 'root' })
export class CurrentProjectService {
  private PathHelper = inject(PathHelperService);
  private apiV3Service = inject(ApiV3Service);

  private currentId:string|null = null;
  private currentName:string|null = null;
  private currentIdentifier:string|null = null;

  constructor() {
    this.detect();
  }

  public get inProjectContext():boolean {
    return this.currentId !== null;
  }

  public get path():string|null {
    if (this.currentIdentifier) {
      return this.PathHelper.projectPath(this.currentIdentifier);
    }

    return null;
  }

  public get apiv3Path():string|null {
    if (this.currentId) {
      return this.apiV3Service.projects.id(this.currentId).toString();
    }

    return null;
  }

  public get id():string|null {
    return this.currentId;
  }

  public get name():string|null {
    return this.currentName;
  }

  public get identifier():string|null {
    return this.currentIdentifier;
  }

  /**
   * Detect the current project from its meta tag.
   */
  public detect() {
    const element = getMetaElement('current_project');
    if (element) {
      this.currentId = element.dataset.projectId!;
      this.currentName = element.dataset.projectName!;
      this.currentIdentifier = element.dataset.projectIdentifier!;
    } else {
      this.currentId = null;
      this.currentName = null;
      this.currentIdentifier = null;
    }
  }
}
