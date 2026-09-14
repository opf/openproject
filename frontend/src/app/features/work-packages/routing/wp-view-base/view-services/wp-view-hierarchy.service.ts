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

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Injectable } from '@angular/core';
import { WorkPackageViewHierarchies } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-table-hierarchies';
import { WorkPackageQueryStateService } from './wp-view-base.service';

@Injectable()
export class WorkPackageViewHierarchiesService extends WorkPackageQueryStateService<WorkPackageViewHierarchies> {
  public valueFromQuery(query:QueryResource):WorkPackageViewHierarchies {
    const value = new WorkPackageViewHierarchies(query.showHierarchies);
    const { current } = this;

    // Take over current collapsed values
    // which are not yet saved
    if (current) {
      value.collapsed = current.collapsed;
    }

    return value;
  }

  public hasChanged(query:QueryResource) {
    return query.showHierarchies !== this.isEnabled;
  }

  public applyToQuery(query:QueryResource) {
    query.showHierarchies = this.isEnabled;

    // We need to visibly load the ancestors when the mode is activated.
    return this.isEnabled;
  }

  /**
   * Return whether the current hierarchy mode is active
   */
  public get isEnabled():boolean {
    return !!(this.current && this.current.isVisible);
  }

  public setEnabled(active = true) {
    const state = { ...this.current, isVisible: active, last: null };
    this.update(state);
  }

  /**
   * Toggle the hierarchy state
   */
  public toggleState():boolean {
    this.setEnabled(!this.isEnabled);
    return this.isEnabled;
  }

  /**
   * Return whether the given wp ID is collapsed.
   */
  public collapsed(wpId:string):boolean {
    return this.current.collapsed[wpId];
  }

  /**
   * Collapse the hierarchy for this work package
   */
  public collapse(wpId:string):void {
    this.setState(wpId, true);
  }

  /**
   * Expand the hierarchy for this work package
   */
  public expand(wpId:string):void {
    this.setState(wpId, false);
  }

  /**
   * Toggle the hierarchy state
   */
  public toggle(wpId:string):void {
    this.setState(wpId, !this.collapsed(wpId));
  }

  /**
   * Set the collapse/expand state of the given work package id.
   */
  private setState(wpId:string, isCollapsed:boolean):void {
    const state = { ...this.current, last: wpId };
    state.collapsed[wpId] = isCollapsed;
    this.update(state);
  }

  /**
   * Get current selection state.
   */
  public get current():WorkPackageViewHierarchies {
    const state = this.lastUpdatedState.value;

    if (state === undefined) {
      return this.initialState;
    }

    if (!state.collapsed) {
      state.collapsed = {};
    }

    return state;
  }

  private get initialState():WorkPackageViewHierarchies {
    return new WorkPackageViewHierarchies(false);
  }
}
