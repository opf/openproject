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

import {opUiComponentsModule} from '../../../angular-modules';
import {Component} from '@angular/core';
import {OnInit, Input} from '@angular/core';
import {downgradeComponent} from '@angular/upgrade/static';
import {HideSectionsService} from 'core-components/common/hide-sections/hide-sections.service';

@Component({
  selector: 'hide-section',
  template: '<span *ngIf="isDisplayed()"><ng-content></ng-content>' +
            '<span style="display: flex; flex: 1 0 0"><a href="" (click)="hideSection()">Remove</a></span></span>'
})
export class HideSectionComponent implements OnInit {
  displayed:boolean = true;

  @Input('sectionName') sectionName:string;

  constructor(protected hideSections:HideSectionsService) {
  }

  ngOnInit() {
  }

  isDisplayed() {
    //console.log('sectionDisplayed');
    return this.hideSections.isDisplayed(this.sectionName);
  }

  hideSection() {
    this.hideSections.hide(this.sectionName);
  }
}

opUiComponentsModule.directive(
  'hideSection',
  downgradeComponent({component: HideSectionComponent})
);
