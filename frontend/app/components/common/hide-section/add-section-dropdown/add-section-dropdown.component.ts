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

import {opUiComponentsModule} from '../../../../angular-modules';
import {Component, Inject, OnDestroy, OnInit} from '@angular/core';
import {downgradeComponent} from '@angular/upgrade/static';
import {HideSectionDefinition, HideSectionService} from 'core-components/common/hide-section/hide-section.service';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {Subscription} from 'rxjs/Subscription';
import {Observable} from 'rxjs/Observable';

@Component({
  selector: 'add-section-dropdown',
  template: require('!!raw-loader!./add-section-dropdown.component.html')
})
export class AddSectionDropdownComponent implements OnInit, OnDestroy {
  selectable:HideSectionDefinition[] = [];
  turnedActive:HideSectionDefinition|null = null;
  texts:{ [key:string]:string } = {};

  private allSubscription:Subscription;

  constructor(protected hideSections:HideSectionService,
              @Inject(I18nToken) protected I18n:op.I18n) {
    this.texts = {
      placeholder: I18n.t('js.placeholders.default'),
      add: I18n.t('js.custom_actions.add')
    };
  }

  ngOnInit() {
    this.allSubscription = Observable.combineLatest(this.hideSections.all$,
                                                    this.hideSections.displayed$)
                                     .subscribe(([all, displayed]) => {
      this.selectable = _.filter(all, all_candidate =>
        !_.some(displayed, displayed_candidate => all_candidate.key === displayed_candidate.key)
      );
    });
  }

  ngOnDestroy() {
    this.allSubscription.unsubscribe();
  }

  show() {
    if (this.turnedActive) {
      this.hideSections.show(this.turnedActive);
      setTimeout(() => { this.turnedActive = null; } );
    }
  }
}

opUiComponentsModule.directive(
  'addSectionDropdown',
  downgradeComponent({component:AddSectionDropdownComponent})
);
