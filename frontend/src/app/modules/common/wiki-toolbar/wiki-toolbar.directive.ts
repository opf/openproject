//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
//++

import {Directive, ElementRef, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Directive({
  selector: '[wiki-toolbar], .wiki-toolbar'
})
export class WikiToolbarDirective implements OnInit {
  public isPreview:boolean = false;

  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef) {

  }

  ngOnInit() {
    const element = jQuery(this.elementRef.nativeElement);
    const help_link_title = this.I18n.t('js.inplace.link_formatting_help');

    const button = document.createElement('button');
    button.classList.add('jstb_help formatting-help-link-button');
    button.setAttribute('type', 'button');
    button.setAttribute('aria-label', help_link_title);
    button.setAttribute('title', help_link_title);

    const PREVIEW_ENABLE_TEXT = this.I18n.t('js.inplace.btn_preview_enable');
    const PREVIEW_DISABLE_TEXT = this.I18n.t('js.inplace.btn_preview_disable');
    const PREVIEW_BUTTON_CLASS = 'jstb_preview';
    let previewButtonAttributes:any = {
      'class': PREVIEW_BUTTON_CLASS + ' icon-preview icon-small',
      'type': 'button',
      'title': PREVIEW_ENABLE_TEXT,
      'aria-label': PREVIEW_ENABLE_TEXT,
      'text': ''
    };

    const wikiToolbar = new (window as any).jsToolBar(this.elementRef.nativeElement);
    wikiToolbar.setHelpLink(button);
    wikiToolbar.draw();

    previewButtonAttributes.click = function() {
      const title = this.isPreview ? PREVIEW_DISABLE_TEXT : PREVIEW_ENABLE_TEXT;
      const toggledClasses = 'icon-preview icon-ticket-edit -active';

      element.closest('.textarea-wrapper')
        .find('.' + PREVIEW_BUTTON_CLASS).attr('title', title)
        .attr('aria-label', title)
        .toggleClass(toggledClasses);
    };

    element
      .closest('.textarea-wrapper')
      .find('.jstb_help')
      .after(jQuery('<button>', previewButtonAttributes));
  }
}
