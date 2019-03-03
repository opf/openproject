//-- copyright
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
//++

import {Component, Input, Output, EventEmitter, OnInit} from '@angular/core';

@Component({
  selector: 'group-edit-in-place',
  templateUrl: './group-edit-in-place.html'
})
export class GroupEditInPlaceComponent implements OnInit {
  @Input() public placeholder:string = '';
  @Input('name') public originalName:string;
  @Input() public key:string;

  @Output() public onValueChange = new EventEmitter<string>();

  public editing = false;

  public name:string;

  ngOnInit():void {
    this.name = this.originalName;

    if (!this.name || this.name.length === 0) {
      // Group name is empty so open in editing mode straight away.
      this.startEditing();
    }
  }

  startEditing() {
    this.editing = true;
  }

  saveEdition(event:KeyboardEvent) {
    this.originalName = this.name;
    this.name = this.name.trim();
    this.leaveEditingMode();
    if (this.originalName !== this.name) {
      this.onValueChange.emit(this.name);
    }

    // Ensure form is not submitted.
    event.preventDefault();
    event.stopPropagation();
    return false;
  }

  reset() {
    this.editing = false;
    this.name = this.originalName;
  }

  leaveEditingMode() {
    // Only leave Editing mode if name not empty.
    if (this.name != null && this.name.trim().length > 0) {
      this.editing = false;
    }
  }
}
