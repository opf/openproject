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

import {Component, ElementRef, Inject, OnDestroy, OnInit} from "@angular/core";
import {I18nToken, OpModalLocalsToken} from "core-app/angular4-transition-utils";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";

@Component({
  template: require('!!raw-loader!./dynamic-content.modal.html')
})
export class DynamicContentModal extends OpModalComponent implements OnInit, OnDestroy {
  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              @Inject(I18nToken) readonly I18n:op.I18n) {

    super(locals, elementRef);
  }


  ngOnInit() {
    super.ngOnInit();

    // Append the dynamic body
    this.$element
      .find('.dynamic-content-modal--wrapper')
      .addClass(this.locals.modalClassName)
      .append(this.locals.modalBody);

    // Register click listeners
    jQuery(document.body).on('click.opdynamicmodal', '.dynamic-content-modal--close-button', (evt) => {
      this.closeMe(evt);
    });
  }

  ngOnDestroy() {
    jQuery(document.body).off('click.opdynamicmodal');
    super.ngOnDestroy();
  }

}
