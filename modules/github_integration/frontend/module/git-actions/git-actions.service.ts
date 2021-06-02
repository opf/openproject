//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import {Injectable} from '@angular/core';
import {WorkPackageResource} from 'core-app/core/hal/resources/work-package-resource';
import formatter from 'tickety-tick-formatter';

// probably not providable in root when we want to cache the formatter and set custom templates
@Injectable({
  providedIn: 'root',
})
export class GitActionsService {
  private formatter = formatter();

  public branchName(workPackage:WorkPackageResource):string {
    return(this.formatter.branch(this.formattingInput(workPackage)));
  }

  public commitMessage(workPackage:WorkPackageResource):string {
    return(this.formatter.commit(this.formattingInput(workPackage)));
  }

  public gitCommand(workPackage:WorkPackageResource):string {
    return(this.formatter.command(this.formattingInput(workPackage)));
  }

  private formattingInput(workPackage: WorkPackageResource) {
    const type = workPackage.type.name || '';
    const id = workPackage.id || '';
    const title = workPackage.subject;
    const url = window.location.origin + workPackage.pathHelper.workPackagePath(id);
    const description = '';

    return({
      id, type, title, url, description
    });
  }
}