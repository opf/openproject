//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { ChangeDetectorRef, Component, ElementRef, Input, OnInit } from '@angular/core';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { filter } from "rxjs/operators";
import { States } from "core-components/states.service";
import { AngularTrackingHelpers } from "core-components/angular/tracking-functions";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'attachment-list',
  templateUrl: './attachment-list.html'
})
export class AttachmentListComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public resource:HalResource;
  @Input() public destroyImmediately = true;

  trackByHref = AngularTrackingHelpers.trackByHref;

  attachments:HalResource[] = [];
  deletedAttachments:HalResource[] = [];

  public $element:JQuery;
  public $formElement:JQuery;

  constructor(protected elementRef:ElementRef,
              protected states:States,
              protected cdRef:ChangeDetectorRef,
              protected halResourceService:HalResourceService) {
    super();
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.updateAttachments();
    this.setupResourceUpdateListener();

    if (!this.destroyImmediately) {
      this.setupAttachmentDeletionCallback();
    }
  }

  public setupResourceUpdateListener() {
    this.states.forResource(this.resource)!
      .values$()
      .pipe(
        this.untilDestroyed(),
        filter(newResource => !!newResource)
      )
      .subscribe((newResource:HalResource) => {
        this.resource = newResource || this.resource;

        this.updateAttachments();
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    if (!this.destroyImmediately) {
      this.$formElement.off('submit.attachment-component');
    }
  }

  public removeAttachment(attachment:HalResource) {
    this.deletedAttachments.push(attachment);
    // Keep the same object as we would otherwise loose the connection to the
    // resource's attachments array. That way, attachments added after removing one would not be displayed.
    // This is bad design.
    const newAttachments = this.attachments.filter((el) => el !== attachment);
    this.attachments.length = 0;
    this.attachments.push(...newAttachments);

    this.cdRef.detectChanges();
  }

  private get attachmentsUpdatable() {
    return (this.resource.attachments && this.resource.attachmentsBackend);
  }

  public setupAttachmentDeletionCallback() {
    this.$formElement = this.$element.closest('form');
    this.$formElement.on('submit.attachment-component', () => {
      this.destroyRemovedAttachments();
    });
  }

  private destroyRemovedAttachments() {
    this.deletedAttachments.forEach((attachment) => {
      this
        .resource
        .removeAttachment(attachment);
    });
  }

  private updateAttachments() {
    if (!this.attachmentsUpdatable) {
      this.attachments = this.resource.attachments.elements;
      return;
    }

    this
      .resource
      .attachments
      .updateElements()
      .then(() => {
        this.attachments = this.resource.attachments.elements;
        this.cdRef.detectChanges();
      });
  }
}
