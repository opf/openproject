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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

import { isHTMLInputElement } from 'core-app/shared/helpers/dom-helpers';

export default class IfcModelDirectUploadController extends Controller {
  static targets = [
    'form',
    'fileInput',
  ];

  static values = {
    setDefaultModelUrl: String,
    setModelTitleUrl: String,
  };

  declare setDefaultModelUrlValue:string;
  declare setModelTitleUrlValue:string;

  declare readonly formTarget:HTMLFormElement;
  declare readonly fileInputTarget:HTMLInputElement;

  setSessionModelTitle(event:Event):void {
    const target = event.target;
    if (!this.isHTMLInputElement(target)) {
      return;
    }

    const fileList = target.files;
    if (fileList === null || fileList.length === 0) {
      return;
    }

    this.fileInputTarget.setCustomValidity('');
    const title = this.trimFileExtension(fileList[0].name);
    const fileSize = String(fileList[0].size);

    void post(this.setModelTitleUrlValue, { body: { title, fileSize }, responseKind: 'json' })
      .then(async (response) => {
        if (!response.unprocessableEntity) { return; }

        const { error } = await response.json as { error:string };

        this.fileInputTarget.setCustomValidity(error);
        this.fileInputTarget.reportValidity();
      });
  }

  setSessionDefaultValue(event:Event):void {
    const target = event.target;
    if (isHTMLInputElement(target)) {
      void post(this.setDefaultModelUrlValue, { body: { isDefault: String(target.checked) } });
    }
  }

  private trimFileExtension(fileName:string):string {
    const fileNameParts = fileName.split('.');
    return fileNameParts.slice(0, -1).join('.');
  }
}
