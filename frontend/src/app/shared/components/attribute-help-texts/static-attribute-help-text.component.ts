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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { StaticAttributeHelpTextModalComponent } from './static-attribute-help-text.modal';


@Component({
  selector: 'opce-static-attribute-help-text',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './static-attribute-help-text.component.html',
})
export class StaticAttributeHelpTextComponent {
  // Attribute pass the modal title and content
  @Input() public title:string;

  @Input() public content:string;

  @HostBinding('class.form--field-inline-buttons-container') className = true;

  readonly text = {
    open_dialog: this.I18n.t('js.help_texts.show_modal'),
  };

  constructor(
    readonly elementRef:ElementRef,
    protected opModalService:OpModalService,
    protected cdRef:ChangeDetectorRef,
    protected injector:Injector,
    protected I18n:I18nService,
  ) {
    populateInputsFromDataset(this);
  }

  public handleClick(event:Event):void {
    this.opModalService.show(StaticAttributeHelpTextModalComponent, this.injector, { title: this.title, content: this.content });

    event.preventDefault();
  }
}
