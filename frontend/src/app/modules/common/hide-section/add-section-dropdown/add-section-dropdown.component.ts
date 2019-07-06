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

import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Component, ElementRef, OnDestroy, OnInit, ViewChild} from "@angular/core";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {HideSectionDefinition, HideSectionService} from "core-app/modules/common/hide-section/hide-section.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

@Component({
  selector: 'add-section-dropdown',
  templateUrl: './add-section-dropdown.component.html'
})
export class AddSectionDropdownComponent implements OnInit, OnDestroy {
  @ViewChild('fallbackOption', { static: true }) private option:ElementRef;

  trackByKey = AngularTrackingHelpers.trackByProperty('key');

  selectable:HideSectionDefinition[] = [];
  active:string[] = [];

  public htmlId:string;
  public placeholder = this.I18n.t('js.placeholders.selection');

  constructor(protected hideSectionService:HideSectionService,
              protected elementRef:ElementRef,
              protected I18n:I18nService) {
  }

  ngOnInit():void {
    this.htmlId = this.elementRef.nativeElement.dataset.htmlId;

    this.hideSectionService
      .displayed
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      ).subscribe(displayed => {
        this.selectable = this.hideSectionService.all
          .filter(el => displayed.indexOf(el.key) === -1)
          .sort((a, b) => a.label.localeCompare(b.label));

        (this.option.nativeElement as HTMLOptionElement).selected = true;
    });
  }

  ngOnDestroy():void {
    // Nothing to do
  }

  show(value:string) {
    this.hideSectionService.show(value);
  }
}

DynamicBootstrapper.register({ cls: AddSectionDropdownComponent, selector: 'add-section-dropdown'});
