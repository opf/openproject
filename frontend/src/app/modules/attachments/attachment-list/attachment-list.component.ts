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

import {Component, Input, OnChanges, OnInit} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {DynamicBootstrapper} from 'core-app/globals/dynamic-bootstrapper';
import {ElementRef} from '@angular/core';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';

@Component({
  selector: 'attachment-list',
  templateUrl: './attachment-list.html'
})
export class AttachmentListComponent implements OnInit, OnChanges {
  @Input() public resource:HalResource;
  @Input() public selfDestroy:boolean = false;

  public $element:JQuery;

  constructor(protected elementRef:ElementRef,
              protected halResourceService:HalResourceService) { }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    if (this.attachmentsUpdatable) {
      this.resource.attachments.updateElements();
    }
  }

  ngOnChanges() {
    if (this.attachmentsUpdatable) {
      this.resource.attachments.updateElements();
    }
  }

  private get attachmentsUpdatable() {
    return (this.resource.attachments && this.resource.attachmentsBackend);
  }
}

DynamicBootstrapper.register({
  selector: 'attachment-list',
  cls: AttachmentListComponent
});
