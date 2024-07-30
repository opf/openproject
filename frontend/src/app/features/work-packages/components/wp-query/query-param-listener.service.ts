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

import { Injectable, Injector } from '@angular/core';
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { TransitionService } from '@uirouter/core';
import { Subject } from 'rxjs';

@Injectable()
export class QueryParamListenerService {
  readonly wpListChecksumService:WorkPackagesListChecksumService = this.injector.get(WorkPackagesListChecksumService);

  readonly wpListService:WorkPackagesListService = this.injector.get(WorkPackagesListService);

  readonly $transitions:TransitionService = this.injector.get(TransitionService);

  public observe$ = new Subject<any>();

  public queryChangeListener:Function;

  constructor(readonly injector:Injector) {
    this.listenForQueryParamsChanged();
  }

  public listenForQueryParamsChanged():any {
    // Listen for param changes
    return this.queryChangeListener = this.$transitions.onSuccess({}, (transition):any => {
      const options = transition.options();
      const params = transition.params('to');

      const newChecksum = this.wpListService.getCurrentQueryProps(params);
      const newId:string = params.query_id ? params.query_id.toString() : null;

      // Avoid performing any changes when we're going to reload
      if (options.reload || (options.custom && options.custom.notify === false)) {
        return true;
      }

      return this.wpListChecksumService
        .executeIfOutdated(newId,
          newChecksum,
          () => {
            this.observe$.next(newChecksum);
          });
    });
  }

  public removeQueryChangeListener() {
    this.queryChangeListener();
  }
}
