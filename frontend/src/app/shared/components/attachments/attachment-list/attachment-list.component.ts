// -- copyright
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

import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  Output,
} from '@angular/core';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';

@Component({
  selector: 'op-attachment-list',
  templateUrl: './attachment-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpAttachmentListComponent extends UntilDestroyedMixin {
  @Input() public attachments:IAttachment[] = [];

  @Input() public collectionKey:string;

  @Input() public showTimestamp = true;

  @Output() public attachmentRemoved = new EventEmitter<void>();

  constructor(
    private readonly attachmentsResourceService:AttachmentsResourceService,
  ) {
    super();
  }

  public removeAttachment(attachment:IAttachment):void {
    this.attachmentsResourceService.removeAttachment(this.collectionKey, attachment).subscribe(() => {
      this.attachmentRemoved.emit();
    });
  }
}
