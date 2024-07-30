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

import { Injectable } from '@angular/core';
import { input } from '@openproject/reactivestates';
import { Observable } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

export type ModelLinks = { [action:string]:any };
export type ModelLinksHash = { [model:string]:ModelLinks };

@Injectable({ providedIn: 'root' })
export class AuthorisationService {
  private links = input<ModelLinksHash>({});

  public initModelAuth(modelName:string, modelLinks:ModelLinks) {
    this.links.doModify((value:ModelLinksHash) => {
      const links = { ...value };
      links[modelName] = modelLinks;
      return links;
    });
  }

  public observeUntil(unsubscribe:Observable<any>) {
    return this.links.values$().pipe(takeUntil(unsubscribe));
  }

  public can(modelName:string, action:string) {
    const links:ModelLinksHash = this.links.getValueOr({});
    return links[modelName] && (action in links[modelName]);
  }

  public cannot(modelName:string, action:string) {
    return !this.can(modelName, action);
  }
}
