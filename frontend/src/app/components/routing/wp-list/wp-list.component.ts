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

import {Component} from "@angular/core";
import {WorkPackagesSetComponent} from "core-components/routing/wp-set/wp-set.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

@Component({
  selector: 'wp-list',
  templateUrl: './wp.list.component.html'
})
export class WorkPackagesListComponent extends WorkPackagesSetComponent {
  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  titleEditingEnabled:boolean;
  selectedTitle?:string;
  staticTitle?:string;
  currentQuery:QueryResource;

  ngOnInit() {
    super.ngOnInit();

    // Update the title whenever the query changes
    this.states.query.resource.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((query) => {
      this.updateTitle(query);
      this.currentQuery = query;
    });
  }

  public setAnchorToNextElement() {
    // Skip to next when visible, otherwise skip to previous
    const selectors = '#pagination--next-link, #pagination--prev-link, #pagination-empty-text';
    const visibleLink = jQuery(selectors)
      .not(':hidden')
      .first();

    if (visibleLink.length) {
      visibleLink.focus();
    }
  }

  public allowed(model:string, permission:string) {
    return this.authorisationService.can(model, permission);
  }

  updateTitle(query:QueryResource) {
    if (query.id) {
      this.selectedTitle = query.name;
      this.titleEditingEnabled = true;
    } else {
      this.selectedTitle =  this.wpStaticQueries.getStaticName(query);
      this.titleEditingEnabled = false;
    }
  }
}
