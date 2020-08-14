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

import {Component} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {DomSanitizer} from "@angular/platform-browser";
import {BcfRestApi} from "core-app/modules/bim/bcf/bcf-constants.const";

export const homescreenNewFeaturesBlockSelector = 'homescreen-new-features-block';

@Component({
  template: `
    <p class="widget-box--additional-info">
      {{ text.descriptionNewFeatures }}
    </p>

    <div class="widget-box--description">
      <p [innerHtml]="currentNewFeatureHtml"></p>

      <a class="widget-box--teaser-image"></a>
    </div>

    <a [href]="teaserWebsiteUrl" target="_blank">{{ text.learnAbout }}</a>
  `,
  selector: homescreenNewFeaturesBlockSelector,
  styleUrls: ['./new-features.component.sass'],
})

/**
 * Component for the homescreen block to promote new features.
 * When updating this for the next release, be sure to cleanup stuff is not needed any more:
 * Locals (js-en.yml), Styles (new-features.component.sass), HTML (above), TS (below)
 */
export class HomescreenNewFeaturesBlockComponent {
  public isStandardEdition:boolean;

  public text = {
    newFeatures: this.i18n.t('js.label_new_features'),
    descriptionNewFeatures: this.i18n.t('js.homescreen.blocks.new_features.text_new_features'),
    learnAbout: this.i18n.t('js.homescreen.blocks.new_features.learn_about'),
  };

  constructor(
    readonly i18n:I18nService,
    readonly domSanitizer:DomSanitizer
  ) {
    this.isStandardEdition = window.OpenProject.isStandardEdition;
  }

  public get teaserWebsiteUrl() {
    let url = this.translated('learn_about_link');
    return this.domSanitizer.bypassSecurityTrustResourceUrl(url);
  }

  public get currentNewFeatureHtml():string {
    return this.translated('current_new_feature_html');
  }

  private translated(key:string):string {
    return this.i18n.t(this.i18nBase + this.i18nPrefix + '.' + key, { list_styling_class: 'widget-box--arrow-links', bcf_api_link: BcfRestApi});
  }

  private i18nBase:string = 'js.homescreen.blocks.new_features.';

  private get i18nPrefix():string {
    return this.isStandardEdition ? "standard" : "bim";
  }
}
