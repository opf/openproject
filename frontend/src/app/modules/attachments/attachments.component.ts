//-- copyright
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
//++

import {Component, ElementRef, Input, OnInit} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {States} from 'core-components/states.service';
import {filter} from 'rxjs/operators';
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

export const attachmentsSelector = 'attachments';

@Component({
  selector: attachmentsSelector,
  templateUrl: './attachments.html'
})
export class AttachmentsComponent extends UntilDestroyedMixin implements OnInit {
  @Input('resource') public resource:HalResource;

  public $element:JQuery;
  public allowUploading:boolean;
  public destroyImmediately:boolean;
  public text:any;

  constructor(protected elementRef:ElementRef,
              protected I18n:I18nService,
              protected states:States,
              protected halResourceService:HalResourceService) {
    super();

    this.text = {
      attachments: this.I18n.t('js.label_attachments'),
    };
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    if (!this.resource) {
      // Parse the resource if any exists
      const source = this.$element.data('resource');
      this.resource = this.halResourceService.createHalResource(source, true);
    }

    this.allowUploading = this.$element.data('allow-uploading');

    if (this.$element.data('destroy-immediately') !== undefined) {
      this.destroyImmediately = this.$element.data('destroy-immediately');
    } else {
      this.destroyImmediately = true;
    }

    this.setupResourceUpdateListener();
  }

  public setupResourceUpdateListener() {
    this.states.forResource(this.resource)!.changes$()
      .pipe(
        this.untilDestroyed(),
        filter(newResource => !!newResource)
      )
      .subscribe((newResource:HalResource) => {
        this.resource = newResource || this.resource;
      });
  }

  // Only show attachment list when allow uploading is set
  // or when at least one attachment exists
  public showAttachments() {
    return this.allowUploading || _.get(this.resource, 'attachments.count', 0) > 0;
  }
}
