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
import { WorkPackageResource } from "core-app/features/hal/resources/work-package-resource";

// probably not providable in root when we want to cache the formatter and set custom templates
@Injectable({
  providedIn: 'root',
})
export class GitActionsService {
  private sanitizeBranchString(str:string):string {
    // See https://stackoverflow.com/a/3651867 for how these rules came in.
    // This sanitization tries to be harsher than those rules
    return str
      .replace(/ +/g, '-') // Spaces become dashes
      .replace(/[\000-\039]/g, '') // ASCII control characters are out
      .replace(/\177/g, '') // DEL is out
      .replace(/#\\\/\?\*\~\^\:\{\}@\.\[\]/g, '') // Some other characters with special rules are out
      .replace(/^[-]+/, ''); // Dashes at the start are removed
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

  private sanitizeShellInput(str:string):string {
    return `"${str
      .replace(/\n/g, '\\/n')
      .replace(/\$/g, '\\$')
      .replace(/\//g, '\\/')
      .replace(/"/g, '\\"')
    }"`;
  }

  public branchName(workPackage:WorkPackageResource):string {
    const { type, id, description } = this.formattingInput(workPackage);
    return `${type}/${id}-${this.sanitizeBranchString(description)}`;
  }

  public commitMessage(workPackage:WorkPackageResource):string {
    const { title, id, description, url } = this.formattingInput(workPackage);
    return `[#${id}] ${title}

${description}

${url}`;
  }

  public gitCommand(workPackage:WorkPackageResource):string {
    const wp = this.formattingInput(workPackage);
    const branch = this.branchName(workPackage);
    const commit = this.commitMessage(workPackage);
    return `git checkout -b ${this.sanitizeShellInput(branch)} && git commit --allow-empty -m ${this.sanitizeShellInput(commit)}`;
  }
}