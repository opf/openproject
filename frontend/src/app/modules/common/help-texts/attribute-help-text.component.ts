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

import {AttributeHelpTextsService} from './attribute-help-text.service';
import {HelpTextDmService} from 'core-app/modules/hal/dm-services/help-text-dm.service';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit
} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {AttributeHelpTextModal} from 'core-app/modules/common/help-texts/attribute-help-text.modal';

export const attributeHelpTextSelector = 'attribute-help-text';

@Component({
  selector: attributeHelpTextSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './attribute-help-text.component.html'
})
export class AttributeHelpTextComponent implements OnInit {
  // Attribute to show help text for
  @Input() public attribute:string;
  @Input() public additionalLabel?:string;

  // Scope to search for
  @Input() public attributeScope:string;
  // Load single id entry if given
  @Input() public helpTextId?:string;

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
              protected cdRef:ChangeDetectorRef,
              protected injector:Injector,
              protected I18n:I18nService) {
  }

  ngOnInit() {
    const element:HTMLElement = this.elementRef.nativeElement;
    if (element.dataset.helpTextId) {
      this.helpTextId = element.dataset.helpTextId!;
      this.attribute = element.dataset.attribute!;
      this.attributeScope = element.dataset.attributeScope!;
      this.additionalLabel = element.dataset.additionalLabel!;
    }


    if (this.helpTextId) {
      this.exists = true;
    } else {
      // Need to load the promise to find out if the attribute exists
      this.load().then((resource) => {
        this.exists = !!resource;
        this.cdRef.detectChanges();
        return resource;
      });
    }
  }

  public handleClick() {
    this.load().then((resource) => {
      this.opModalService.show(AttributeHelpTextModal, this.injector, { helpText: resource });
    });
  }

  private load() {
    if (this.helpTextId) {
      return this.helpTextDm.load(this.helpTextId);
    } else {
      return this.attributeHelpTexts.require(this.attribute, this.attributeScope);
    }
  }
}

