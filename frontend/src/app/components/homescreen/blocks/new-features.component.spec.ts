// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {DebugElement} from "@angular/core";

import {ComponentFixture, fakeAsync, TestBed} from '@angular/core/testing';
import {By} from "@angular/platform-browser";
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { HomescreenNewFeaturesBlockComponent } from './new-features.component';

describe('shows edition-specific content', () => {
  let app:HomescreenNewFeaturesBlockComponent;
  let fixture:ComponentFixture<HomescreenNewFeaturesBlockComponent>;
  let element:DebugElement;

  beforeEach(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        HomescreenNewFeaturesBlockComponent
      ],
      providers: [I18nService]
    }).compileComponents();


    fixture = TestBed.createComponent(HomescreenNewFeaturesBlockComponent);
    app = fixture.debugElement.componentInstance;
    element = fixture.debugElement.query(By.css('div.widget-box--description p'));
  });

  it('should render bim text for bim edition', fakeAsync(() => {
    app.isStandardEdition = false;

    fixture.detectChanges();

    // checking for missing translation key as translations are not loaded in specs
    expect(element.nativeElement.textContent).toContain(".bim.current_new_feature_html");
  }));

  it('should render standard text for standard edition', fakeAsync(() => {
    app.isStandardEdition = true;

    fixture.detectChanges();

    // checking for missing translation key as translations are not loaded in specs
    expect(element.nativeElement.textContent).toContain(".standard.current_new_feature_html");
  }));
});
