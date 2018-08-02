// // -- copyright
// // OpenProject is a project management system.
// // Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
// //
// // This program is free software; you can redistribute it and/or
// // modify it under the terms of the GNU General Public License version 3.
// //
// // OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// // Copyright (C) 2006-2013 Jean-Philippe Lang
// // Copyright (C) 2010-2013 the ChiliProject Team
// //
// // This program is free software; you can redistribute it and/or
// // modify it under the terms of the GNU General Public License
// // as published by the Free Software Foundation; either version 2
// // of the License, or (at your option) any later version.
// //
// // This program is distributed in the hope that it will be useful,
// // but WITHOUT ANY WARRANTY; without even the implied warranty of
// // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// // GNU General Public License for more details.
// //
// // You should have received a copy of the GNU General Public License
// // along with this program; if not, write to the Free Software
// // Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
// //
// // See doc/COPYRIGHT.rdoc for more details.
// // ++
//
// import {Component, ElementRef, HostListener, OnDestroy, OnInit, Renderer2, ViewChild} from '@angular/core';
// import {ContainHelpers} from 'core-app/modules/common/focus/contain-helpers';
// import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
// import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
// import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
//
// export const editableToolbarSelector = 'op-editable-toolbar-title\'';
//
// @Component({
//   selector: editableToolbarSelector,
//   template: `
//     <div class="title-container">
//       <h2 *ngIf="!active" [textContent]="title"></h2>
//
//     </div>
//   `
// })
// export class EditableToolbarComponent implements OnInit {
//   public title:string;
//   public fieldName:string;
//
//   constructor(private elementRef:ElementRef) {
//   }
//
//   ngOnInit() {
//     const $element = jQuery(this.elementRef.nativeElement);
//
//   }
// }
//
// DynamicBootstrapper.register({
//   selector: editableToolbarSelector, cls: EditableToolbarComponent
// });
