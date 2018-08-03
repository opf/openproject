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

import {Component, Input, OnInit, OnDestroy} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {DynamicBootstrapper} from 'core-app/globals/dynamic-bootstrapper';
import {ElementRef} from '@angular/core';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {States} from 'core-components/states.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {filter, takeUntil} from 'rxjs/operators';

@Component({
  selector: 'attachments',
  templateUrl: './attachments.html'
})
export class AttachmentsComponent implements OnInit, OnDestroy {
  @Input('resource') public resource:HalResource;

  public $element:JQuery;
  public allowUploading:boolean;
  public destroyImmediately:boolean;
  public text:any;
  public $formElement:JQuery;
  public initialAttachments:HalResource[];

  constructor(protected elementRef:ElementRef,
              protected I18n:I18nService,
              protected states:States,
              protected halResourceService:HalResourceService) {

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

    this.setupAttachmentDeletionCallback();
    this.setupResourceUpdateListener();
  }

  public setupAttachmentDeletionCallback() {
    this.memoizeCurrentAttachments();

    this.$formElement = this.$element.closest('form');
    this.$formElement.on('submit.attachment-component', () => {
      this.destroyRemovedAttachments();
    });
  }

  public setupResourceUpdateListener() {
    this.states.forResource(this.resource).changes$()
      .pipe(
        takeUntil(componentDestroyed(this)),
        filter(newResource => !!newResource)
      )
      .subscribe((newResource:HalResource) => {
        this.resource = newResource || this.resource;

        if (this.destroyImmediately) {
          this.destroyRemovedAttachments();
          this.memoizeCurrentAttachments();
        }
      });
  }

  ngOnDestroy() {
    this.$formElement.off('submit.attachment-component');
  }

  // Only show attachment list when allow uploading is set
  // or when at least one attachment exists
  public showAttachments() {
    return this.allowUploading || _.get(this.resource, 'attachments.count', 0) > 0;
  }

  private destroyRemovedAttachments() {
    let missingAttachments = _.differenceBy(this.initialAttachments,
      this.resource.attachments.elements,
      (attachment:HalResource) => attachment.id);

    if (missingAttachments.length) {
      missingAttachments.forEach((attachment) => {
        this
          .resource
          .removeAttachment(attachment);
      });
    }
  }

  private memoizeCurrentAttachments() {
    this.initialAttachments = _.clone(this.resource.attachments.elements);
  }
}

DynamicBootstrapper.register({ selector: 'attachments', cls: AttachmentsComponent, embeddable: true });
