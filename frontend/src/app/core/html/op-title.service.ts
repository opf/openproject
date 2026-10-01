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

import { Title } from '@angular/platform-browser';
import { Injectable, inject } from '@angular/core';
import { getMetaContent } from '../setup/globals/global-helpers';

const titlePartsSeparator = ' | ';

@Injectable({ providedIn: 'root' })
export class OpTitleService {
  private titleService = inject(Title);


  public get current():string {
    return this.titleService.getTitle();
  }

  public get base():string {
    return getMetaContent('app_title');
  }

  public get titleParts():string[] {
    return this.current.split(titlePartsSeparator);
  }

  public get appTitle():string {
    return this.titleParts[this.titleParts.length - 1];
  }

  public setFirstPart(value:string) {
    if (this.current.includes(this.base) && this.current.includes(titlePartsSeparator)) {
      const parts = this.titleParts;
      parts[0] = value;
      this.titleService.setTitle(parts.join(titlePartsSeparator));
    } else {
      const newTitle = [value, this.base].join(titlePartsSeparator);
      this.titleService.setTitle(newTitle);
    }
  }
}
