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

import {opUiComponentsModule} from '../../../angular-modules';
import {AttributeHelpTextsService} from './attribute-help-text.service';
import {HelpTextDmService} from 'core-app/modules/hal/dm-services/help-text-dm.service';
import {Component, ElementRef, Inject, Input, OnInit} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {AttributeHelpTextModal} from 'core-components/common/help-texts/attribute-help-text.modal';
import {downgradeComponent} from '@angular/upgrade/static';

@Component({
  selector: 'attribute-help-text',
  template: require('!!raw-loader!./help-text.directive.html')
})
export class AttributeHelpTextComponent implements OnInit {
  // Attribute to show help text for
  @Input() public attribute:string;
  @Input() public additionalLabel?:string;

  // Scope to search for
  @Input() public attributeScope:string;
  // Load single id entry if given
  @Input() public helpTextId?:string;

  public optionaltitle?:string;
  public exists:boolean = false;

  readonly text = {
    open_dialog: this.I18n.t('js.help_texts.show_modal'),
    'edit': this.I18n.t('js.button_edit'),
    'close': this.I18n.t('js.button_close')
  };

  constructor(protected elementRef:ElementRef,
              protected helpTextDm:HelpTextDmService,
              protected attributeHelpTexts:AttributeHelpTextsService,
              protected opModalService:OpModalService,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  ngOnInit() {
    if (this.helpTextId) {
      this.exists = true;
    } else {
      // Need to load the promise to find out if the attribute exists
      this.load().then((resource) => {
        this.exists = !!resource;
        return resource;
      });
    }
  }

  public handleClick() {
    this.load().then((resource) => {
      this.opModalService.show(AttributeHelpTextModal, { helpText: resource });
    });
  }

  private async load() {
    if (this.helpTextId) {
      return this.helpTextDm.load(this.helpTextId);
    } else {
      return this.attributeHelpTexts.require(this.attribute, this.attributeScope);
    }
  }
}

opUiComponentsModule.component('attributeHelpText', downgradeComponent({ component: AttributeHelpTextComponent }));
