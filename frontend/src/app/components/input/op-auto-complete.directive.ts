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

import {CurrentProjectService} from '../projects/current-project.service';
import {Directive, ElementRef, Input, OnChanges} from "@angular/core";
import {AutoCompleteHelperService} from "core-components/input/auto-complete-helper.service";

@Directive({
  selector: '[op-auto-complete]',
})
export class OpAutoCompleteDirective implements OnChanges {
  @Input() public opAutoCompleteProjectId:string|null|undefined;

  constructor(readonly elementRef:ElementRef,
              readonly AutoCompleteHelper:AutoCompleteHelperService,
              readonly currentProject:CurrentProjectService) {
  }

  public ngOnChanges() {
    this.opAutoCompleteProjectId = this.opAutoCompleteProjectId || this.currentProject.id;

    // Target both regular textareas and wysiwyg wrapper
    const element = jQuery(this.elementRef.nativeElement);
    const targets = element.add(element.find('.op-ckeditor-wrapper'));

    // Ensure the autocompleter gets enabled on project id changes.
    this.AutoCompleteHelper.enableTextareaAutoCompletion(targets, this.opAutoCompleteProjectId);
  }
}
