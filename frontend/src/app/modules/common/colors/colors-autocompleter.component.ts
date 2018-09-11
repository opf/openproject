// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

import {Component, ElementRef, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

export const selector = 'colors-autocompleter';

@Component({
  selector: selector,
  template: '',
})

export class ColorsAutocompleter implements OnInit {
  private $element:JQuery;
  private $select:JQuery;

  constructor(private readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.$select = jQuery(this.$element.parent().find('select.colors-autocomplete'));

    this.$select.removeClass('form--select');
    this.setupSelect2();
  }

  protected formatter(state:any) {
    const item:JQuery = jQuery(state.element);
    const color = item.data('color');
    const contrastingColor = item.data('background');
    const bright = item.data('bright');

    // Special case, no color
    if (!color) {
      const div = jQuery('<div>')
      .append(item.text())
      .addClass('ui-menu-item-wrapper');

      return div;
    }

    const colorSquare = jQuery('<span>')
      .addClass('color--preview')
      .css('background-color', color);

    const colorText = jQuery('<span>')
      .addClass('color--text-preview')
      .css('color', bright ? '#333333' : '#FFFFFF')
      .css('background-color', color)
      .text(item.text());

    const div = jQuery('<div>')
      .append(colorSquare)
      .append(colorText)
      .addClass('ui-menu-item-wrapper');

    return div;
  }

  protected setupSelect2() {
    this.$select.select2({
      formatResult: this.formatter,
      formatSelection: this.formatter,
      escapeMarkup: (m:any) => m
    });
  }
}

DynamicBootstrapper.register({
  selector: selector,
  cls: ColorsAutocompleter
});

