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

import {Component, ElementRef, Inject, Input, OnInit} from '@angular/core';
import {opUiComponentsModule} from 'core-app/angular-modules';
import {downgradeComponent} from '@angular/upgrade/static';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {AutocompleteSelectDecorationComponent} from 'core-components/common/autocomplete-select-decoration/autocomplete-select-decoration.component';
import {ColorContrast} from 'core-components/a11y/color-contrast.functions';

interface ColorAutocompleteItem {
  id:number;
  label:string;
  color:string;
  value:string;
}

@Component({
  template: require('!!raw-loader!./colors-autocompleter.component.html'),
  selector: 'colors-autocompleter',
})

export class ColorsAutocompleter extends AutocompleteSelectDecorationComponent<ColorAutocompleteItem> {

  protected getItems() {
    _.each(this.$select.find('option'), option => {
      let $option = jQuery(option);
      let text = $option.text();

      let item = {
        id: $option.prop('value'),
        color: $option.data('color'),
        label: text,
        value: text
      };

      this.allItems.push(item);

      if ($option.prop('selected')) {
        this.selectedItems.push(item);
      }
    });
  }

  public get selectedColorIsBright():boolean {
    return !!this.selectedColor && ColorContrast.tooBrightForWhite(this.selectedColor);
  }

  public get fgColor() {
    if (this.selectedColor) {
      return ColorContrast.getColorPatch(this.selectedColor).fg;
    }

    return null;
  }

  public get bgColor() {
    if (this.selectedColor) {
      return ColorContrast.getColorPatch(this.selectedColor).bg;
    }

    return null;
  }

  public get selectedItem():ColorAutocompleteItem|undefined {
    return this.selectedItems.length > 0 ? this.selectedItems[0] : undefined;
  }

  public get selectedColor():string|undefined {
    return this.selectedItem ? this.selectedItem.color : undefined;
  }

  protected setupAutocompleter() {
    super.setupAutocompleter();

    const autocompleter = this.$input.autocomplete('instance');
    const menu = autocompleter.menu;

    this.$input.focus(function() {
      autocompleter.search();
    });

    autocompleter._renderItem = function(this:any, ul:JQuery, item:ColorAutocompleteItem) {
      const term = this.element.val();
      const patch = ColorContrast.getColorPatch(item.color);

      const colorSquare = jQuery('<span>')
        .addClass('color--preview')
        .css('background-color', item.color);

      const colorText = jQuery('<span>')
        .addClass('color--text-preview')
        .css('color', patch.fg)
        .css('background-color', patch.bg)
        .text(item.label);

      const div = jQuery('<div>')
        .append(colorSquare)
        .append(colorText)
        .addClass('ui-menu-item-wrapper');

      const element = jQuery('<li>')
        .append(div)
        .appendTo(ul);

      return element;
    };
  }
}

opUiComponentsModule.directive(
  'colorsAutocompleter',
  downgradeComponent({component: ColorsAutocompleter})
);
