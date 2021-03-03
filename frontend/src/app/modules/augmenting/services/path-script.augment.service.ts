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


import { Inject, Injectable } from "@angular/core";
import { DOCUMENT } from "@angular/common";
import { debugLog } from "core-app/helpers/debug_output";

@Injectable({ providedIn: 'root' })
export class PathScriptAugmentService {

  constructor(@Inject(DOCUMENT) protected documentElement:Document) {
  }

  /**
   * Import required javascript paths from backend-rendered pages
   * This provides a replacement for the asset pipeline that was previously used
   * to load javascripts in the backend.
   *
   * This approach retains the ability to dynamically load code (from a specific set of paths only)
   * while defining the dependency in the rails template to ensure developer visibility.
   */
  public loadRequiredScripts() {
    const matches = this.documentElement.querySelectorAll<HTMLMetaElement>('meta[name="required_script"]');
    for (let i = 0; i < matches.length; ++i) {
      const name = matches[i].content;
      debugLog("Loading required script " + name);
      import('../dynamic-scripts/' + name);
    }
  }
}
