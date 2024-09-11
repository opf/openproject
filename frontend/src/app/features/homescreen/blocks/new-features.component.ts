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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';
import { BcfRestApi } from 'core-app/features/bim/bcf/bcf-constants.const';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';

// The key used in the I18n files to distinguish between versions.
const OpVersionI18n = '14_5';

const OpReleaseURL = 'https://www.openproject.org/docs/release-notes/14-5-0/';

/** Update the teaser image to the next version */
const featureTeaserImage = `${OpVersionI18n}_features.png`;

@Component({
  template: `
    <div class="op-new-features">
      <p class="widget-box--additional-info">
        {{ text.descriptionNewFeatures }}
      </p>
      <div class="widget-box--description">
        <p [innerHtml]="currentNewFeatureHtml"></p>
        <img
          class="widget-box--teaser-image op-new-features--teaser-image"
          role="presentation"
          [src]="new_features_image"/>
      </div>

      <a [href]="teaserWebsiteUrl" target="_blank">{{ text.learnAbout }}</a>
    </div>
  `,
  selector: 'opce-homescreen-new-features-block',
  styleUrls: ['./new-features.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})

/**
 * Component for the homescreen block to promote new features.
 * When updating this for the next release, be sure to cleanup stuff is not needed any more:
 * Locals (js-en.yml), Styles (new-features.component.sass), HTML (above), TS (below)
 */
export class HomescreenNewFeaturesBlockComponent {
  public isStandardEdition:boolean;

  /** Set to true if BIM has it's own changes */
  hasBimChanges = false;

  /** Update the feature image appropriately */
  new_features_image = imagePath(featureTeaserImage);

  public text = {
    newFeatures: this.i18n.t('js.label_new_features'),
    descriptionNewFeatures: this.i18n.t('js.homescreen.blocks.new_features.text_new_features'),
    learnAbout: this.i18n.t('js.homescreen.blocks.new_features.learn_about'),
  };

  constructor(
    readonly i18n:I18nService,
    readonly domSanitizer:DomSanitizer,
  ) {
    this.isStandardEdition = window.OpenProject.isStandardEdition;
  }

  public get teaserWebsiteUrl() {
    return this.domSanitizer.bypassSecurityTrustResourceUrl(OpReleaseURL);
  }

  public get currentNewFeatureHtml():string {
    return this.translated('new_features_html');
  }

  private get translatedEdition():string {
    if (this.hasBimChanges && !this.isStandardEdition) {
      return 'bim';
    }

    return 'standard';
  }

  private translated(key:string):string {
    return this.i18n.t(
      `js.homescreen.blocks.new_features.${OpVersionI18n}.${this.translatedEdition}.${key}`,
      { list_styling_class: 'widget-box--arrow-links', bcf_api_link: BcfRestApi },
    );
  }
}
