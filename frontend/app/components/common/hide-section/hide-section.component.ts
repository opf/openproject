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

import {Component, ElementRef, Input, OnDestroy, OnInit} from '@angular/core';
import {downgradeComponent} from '@angular/upgrade/static';
import {HideSectionService} from 'core-components/common/hide-section/hide-section.service';
import {distinctUntilChanged, map, take} from 'rxjs/operators';
import {Subscription} from 'rxjs/Subscription';
import {opUiComponentsModule} from '../../../angular-modules';

@Component({
  selector: 'hide-section',
  template: '<span *ngIf="displayed"><ng-content></ng-content></span>'
})
export class HideSectionComponent implements OnInit, OnDestroy {
  displayed:boolean = false;

  private displayedSubscription:Subscription;
  private initializationSubscription:Subscription;

  @Input() sectionName:string;
  @Input() onDisplayed:Function;

  constructor(protected hideSection:HideSectionService,
              private elementRef:ElementRef) {
  }

  ngOnInit() {
    let mappedDisplayed = this.hideSection.displayed$
      .pipe(
        map(all_displayed => _.some(all_displayed, candidate => candidate.key === this.sectionName))
      );

    this.initializationSubscription = mappedDisplayed
      .pipe(
        take(1)
      )
      .subscribe(show => {
        jQuery(this.elementRef.nativeElement).addClass('-initialized');
      });

    this.displayedSubscription = mappedDisplayed
      .pipe(
        distinctUntilChanged()
      )
      .subscribe(show => {
        this.displayed = show;

        if (this.displayed && this.onDisplayed !== undefined) {
          setTimeout(this.onDisplayed());
        }
      });
  }

  ngOnDestroy() {
    this.displayedSubscription.unsubscribe();
    this.initializationSubscription.unsubscribe();
  }
}

opUiComponentsModule.directive(
  'hideSection',
  downgradeComponent({component: HideSectionComponent})
);
