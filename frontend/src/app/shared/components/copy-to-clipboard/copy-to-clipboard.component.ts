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

import { ChangeDetectionStrategy, Component, ElementRef, OnInit } from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

import { CopyToClipboardService } from './copy-to-clipboard.service';

@Component({
  template: '',
  selector: 'opce-copy-to-clipboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class CopyToClipboardComponent implements OnInit {
  public clickTarget:string;

  public clipboardTarget:string;

  private target:JQuery;

  constructor(
    readonly toastService:ToastService,
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    protected copyToClipboardService:CopyToClipboardService,
  ) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    // Get inputs as attributes since this is a bootstrapped directive
    this.clickTarget = element.getAttribute('click-target');
    this.clipboardTarget = element.getAttribute('clipboard-target');

    jQuery(this.clickTarget).on('click', (evt:JQuery.TriggeredEvent) => this.onClick(evt));

    element.classList.add('copy-to-clipboard');
    this.target = jQuery(this.clipboardTarget ? this.clipboardTarget : element);
  }

  onClick($event:JQuery.TriggeredEvent) {
    $event.preventDefault();
    // Select the text in case the clipboard is not supported by the browser
    this.target.select().focus();
    this.copyToClipboardService.copy(String(this.target.val()));
  }
}
