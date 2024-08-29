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

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import {
  HideSectionDefinition,
  HideSectionService,
} from 'core-app/shared/components/hide-section/hide-section.service';
import { trackByProperty } from 'core-app/shared/helpers/angular/tracking-functions';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';


@Component({
  selector: 'opce-add-section-dropdown',
  templateUrl: './add-section-dropdown.component.html',
})
export class AddSectionDropdownComponent extends UntilDestroyedMixin implements OnInit {
  @ViewChild('fallbackOption', { static: true }) private option:ElementRef;

  trackByKey = trackByProperty('key');

  selectable:HideSectionDefinition[] = [];

  active:string[] = [];

  public htmlId:string;

  public placeholder = this.I18n.t('js.placeholders.selection');

  constructor(
    protected hideSectionService:HideSectionService,
    protected elementRef:ElementRef,
    protected I18n:I18nService,
  ) {
    super();
  }

  ngOnInit():void {
    this.htmlId = this.elementRef.nativeElement.dataset.htmlId;

    this.hideSectionService
      .displayed
      .values$()
      .pipe(
        this.untilDestroyed(),
      ).subscribe((displayed) => {
      this.selectable = this.hideSectionService.all
        .filter((el) => displayed.indexOf(el.key) === -1)
        .sort((a, b) => a.label.localeCompare(b.label));

      (this.option.nativeElement as HTMLOptionElement).selected = true;
    });
  }

  show(value:string) {
    this.hideSectionService.show(value);
  }
}
