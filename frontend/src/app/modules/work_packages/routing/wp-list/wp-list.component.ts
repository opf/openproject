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

import {Component, OnDestroy} from "@angular/core";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {OpTitleService} from "core-components/html/op-title.service";
import {WorkPackagesSetComponent} from "core-app/modules/work_packages/routing/wp-set/wp-set.component";

@Component({
  selector: 'wp-list',
  templateUrl: './wp.list.component.html'
})
export class WorkPackagesListComponent extends WorkPackagesSetComponent implements OnDestroy {
  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  titleEditingEnabled:boolean;
  selectedTitle?:string;
  currentQuery:QueryResource;
  unRegisterTitleListener:Function;

  private readonly titleService:OpTitleService = this.injector.get(OpTitleService);

  ngOnInit() {
    super.ngOnInit();

    // Update title on entering this state
    this.unRegisterTitleListener = this.$transitions.onSuccess({to: 'work-packages.list'}, () => {
      if (this.selectedTitle) {
        this.titleService.setFirstPart(this.selectedTitle);
      }
    });

    // Update the title whenever the query changes
    this.tableState.query.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((query) => {
      this.updateTitle(query);
      this.currentQuery = query;
    });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.unRegisterTitleListener();
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

    // Update the title if we're in the list state alone
    if (this.$state.current.name === 'work-packages.list') {
      this.titleService.setFirstPart(this.selectedTitle);
    }
  }

  protected loadCurrentQuery() {
    return super.loadCurrentQuery()
                .then(() => {
                  return this.tableState.rendered.valuesPromise();
                });
  }
}
