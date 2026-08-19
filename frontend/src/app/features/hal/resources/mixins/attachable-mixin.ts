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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';

// eslint-disable-next-line
type Constructor<T = object> = new (...args:any[]) => T;

export function Attachable<TBase extends Constructor<HalResource>>(Base:TBase) {
  return class extends Base {
    public attachments:AttachmentCollectionResource;

    /**
     * Return whether the user is able to upload an attachment.
     *
     * If either the `addAttachment` link is provided or the resource is being created,
     * adding attachments is allowed.
     */
    public get canAddAttachments():boolean {
      return !!((this as HalResource).$links as unknown&{ addAttachment?:HalLink }).addAttachment || isNewResource(this);
    }

    /**
     * Try to find an existing file's download URL given its filename
     * @param file
     */
    public lookupDownloadLocationByName(file:string):string|null {
      if (!(this.attachments && this.attachments.elements)) {
        return null;
      }

      const match = this.attachments.elements.find((res:HalResource) => res.name === file);
      return !match ? null : (match.staticDownloadLocation as HalLink)?.href;
    }

    public $initialize(source:unknown) {
      super.$initialize(source);

      const attachments = this.attachments || { $source: {}, elements: [] };
      this.attachments = new AttachmentCollectionResource(
        this.injector,
        attachments,
        false,
        this.halInitializer,
        'HalResource',
      );
    }
  };
}
