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

import {Component, Injector} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {boardTeaserWebsiteURL} from "core-app/modules/boards/board-constants.const";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {BoardVideoTeaserModalComponent} from "core-app/modules/boards/board/board-video-teaser-modal/board-video-teaser-modal.component";
import {DomSanitizer} from "@angular/platform-browser";

@Component({
  template: `
    <p class="widget-box--additional-info">
      {{ text.descriptionNewFeatures }}
    </p>

    <div class="widget-box--description">
      <p [innerHtml]="text.currentNewFeatureHtml"></p>

      <a class="widget-box--teaser-image" (click)="showBoardTeaserVideo()"></a>
    </div>

    <a [href]="boardTeaserWebsiteUrl()" target="_blank">{{ text.learnAbout }}</a>
  `,
  selector: 'homescreen-new-features-block',
  styleUrls: ['./new-features.component.sass'],
})

/**
 * Component for the homescreen block to promote new features.
 * When updating this for the next release, be sure to cleanup stuff is not needed any more:
 * Locals (js-en.yml), Styles (new-features.component.sass), HTML (above), TS (below)
 * Further cleanup additional stuff (and update this list): The boardVideoTeaserModal, the image shown as modalLink
 */
export class HomescreenNewFeaturesBlockComponent {
  public text = {
    newFeatures: this.i18n.t('js.label_new_features'),
    descriptionNewFeatures: this.i18n.t('js.homescreen.blocks.new_features.text_new_features'),
    currentNewFeatureHtml: this.i18n.t('js.homescreen.blocks.new_features.current_new_feature_html'),
    learnAbout: this.i18n.t('js.homescreen.blocks.new_features.learn_about'),
    imageAltText: this.i18n.t('js.homescreen.blocks.new_features.image_alt_text'),
  };

  constructor(readonly i18n:I18nService,
              readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly domSanitizer:DomSanitizer) {
  }

  public showBoardTeaserVideo() {
    this.opModalService.show(
      BoardVideoTeaserModalComponent,
      this.injector
    );
  }

  public boardTeaserWebsiteUrl() {
    return this.domSanitizer.bypassSecurityTrustResourceUrl(boardTeaserWebsiteURL);
  }
}

DynamicBootstrapper.register({ selector: 'homescreen-new-features-block', cls: HomescreenNewFeaturesBlockComponent  });
