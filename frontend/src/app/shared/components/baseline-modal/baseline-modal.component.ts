// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
  Component,
  HostBinding,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  selector: 'op-baseline-modal',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './baseline-modal.component.html',
  styleUrls: ['./baseline-modal.component.sass'],
})
export class OpBaselineModalComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-baseline-modal') className = true;

  public opened = false;

  public text = {
    toggle_title: this.I18n.t('js.show_changes.toggle_title'),
    header_description: this.I18n.t('js.show_changes.header_description'),
    clear: this.I18n.t('js.show_changes.clear'),
    apply: this.I18n.t('js.show_changes.apply'),
  };

  constructor(
    readonly I18n:I18nService,
  ) {
    super();
  }

  public toggleOpen():void {
    this.opened = !this.opened;
  }

  public clearSelection():void {
  }

  public onSubmit(e:Event):void {
    e.preventDefault();

    this.close();
  }

  public close():void {
    this.opened = false;
  }
}
