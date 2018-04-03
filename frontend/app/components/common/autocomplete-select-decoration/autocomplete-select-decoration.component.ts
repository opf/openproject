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

interface AutocompleteSelectDecorationItem {
  id:number;
  label:string;
  value:string;
}

@Component({
  template: require('!!raw-loader!./autocomplete-select-decoration.component.html'),
  selector: 'autocomplete-select-decoration',
})

export class AutocompleteSelectDecorationComponent implements OnInit {

  public selectedItems:AutocompleteSelectDecorationItem[] = [];
  private allItems:AutocompleteSelectDecorationItem[] = [];
  private $select:any = null;
  private $input:any = null;
  private isMulti:boolean = true;
  private label:string;

  @Input('label') labelOverride:string|null = null;

  constructor(private elementRef:ElementRef,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  public remove(item:AutocompleteSelectDecorationItem) {
    _.remove(this.selectedItems, (selected) => selected.id === item.id);

    let val = this.$select.val();
    _.remove(val, (id) => id === item.id);
    this.$select.val(val);
  }

  public ngOnInit() {
    this.setDomElements();

    this.switchIds();
    this.getItems();
    this.setupAutocompleter();

    this.setInitialized();
  }

  public editUnlessMulti() {
    if (this.isMulti) {
      return;
    }

    this.setValue(null);

    setTimeout(() => { this.$input.focus(); });
  }

  public get placeholderText() {
    let key:string;

    if (this.isMulti) {
      key = 'js.autocomplete_select.placeholder.multi';
    } else {
      key = 'js.autocomplete_select.placeholder.single';
    }

    return I18n.t(key, { name: this.label });
  }

  public removeItemText(item:AutocompleteSelectDecorationItem) {
    return I18n.t('js.autocomplete_select.remove', { name: item.value });
  }

  public ariaLabelText(item:AutocompleteSelectDecorationItem) {
    return I18n.t('js.autocomplete_select.active', { label: this.label, name: item.value });
  }

  private getItems() {
    _.each(this.$select.find('option'), option => {
      let $option = jQuery(option);
      let text = $option.text();

      let item = {
        id: $option.prop('value'),
        label: text,
        value: text
      };

      this.allItems.push(item);

      if ($option.prop('selected')) {
        this.selectedItems.push(item);
      }
    });
  }

  private setupAutocompleter() {
    let autocompleteOptions = {
      delay: 100,
      minLength: 0,
      position: { my: 'left top', at: 'left bottom', collision: 'flip' },
      classes: {
        'ui-autocomplete': 'form--select-autocompleter'
      },
      source: (request:{ term:string }, response:Function) => {
        let available = _.difference(this.allItems, this.selectedItems);
        let withTerm = _.filter(available, (item) =>
          item.value.toLowerCase().indexOf(request.term.toLowerCase()) !== -1
        );

        response(withTerm);
      },
      select: (evt:JQueryEventObject, ui:any) => {
        this.setValue(ui.item);

        this.$input.val('');
        return false;
      }
    } as any;

    this.$input.autocomplete(autocompleteOptions);

    // Disable handling all dashes as dividers
    // https://github.com/jquery/jquery-ui/blob/master/ui/widgets/menu.js#L347
    // as we use them as placeholders.
    (this.$input.autocomplete('instance')).menu._isDivider = () => false;
  }

  private switchIds() {
    let id = this.$select.prop('id');
    this.$input.prop('id', id);
    this.$select.prop('id', '');
  }

  private setDomElements() {
    const $element = this.thisElement;

    this.$input = $element.find('.form--input.-autocomplete');
    this.$select = $element.find('select');
    this.label = this.labelOverride || jQuery("label[for='" + this.$select.prop('id') + "']").text();
    this.isMulti = this.$select.prop('multiple');
  }

  private setInitialized() {
    this.$select.hide();

    this.thisElement.addClass('-initialized');
  }

  private get thisElement() {
    return jQuery(this.elementRef.nativeElement);
  }

  private setValue(item:AutocompleteSelectDecorationItem|null) {
    if (item === null) {
      this.selectedItems = [];
    } else if (this.isMulti) {
      this.selectedItems.push(item);
    } else {
      this.selectedItems = [item];
    }

    let ids = _.map(this.selectedItems, (item) => item.id);

    if (this.isMulti) {
      this.$select.val(ids);
    } else {
      this.$select.val(ids[0]);
    }
  }
}

opUiComponentsModule.directive(
  'autocompleteSelectDecoration',
  downgradeComponent({component: AutocompleteSelectDecorationComponent})
);
