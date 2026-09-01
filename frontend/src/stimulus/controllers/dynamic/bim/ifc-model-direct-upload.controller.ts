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

export default class IfcModelDirectUploadController extends Controller {
  static targets = ['form'];

  static values = {
    setDefaultModelUrl: String,
    setModelTitleUrl: String,
  };

  declare setDefaultModelUrlValue:string;
  declare setModelTitleUrlValue:string;

  declare readonly formTarget:HTMLFormElement;

  connect():void {
    this.removeAuthenticityToken();
  }

  updateSessionModelTitle(event:Event):void {
    const target = event.target;
    if (!this.isHTMLInputElement(target)) {
      return;
    }

    const fileList = target.files;
    if (fileList === null || fileList.length === 0) {
      return;
    }

    const title = this.trimFileExtension(fileList[0].name);
    const fileSize = String(fileList[0].size);

    void fetch(this.setModelTitleUrlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-CSRF-Token': this.csrfToken,
      },
      body: new URLSearchParams({ title, fileSize }),
    });

  }

  setSessionDefaultValue(event:Event):void {
    const target = event.target;
    if (this.isHTMLInputElement(target)) {
      void fetch(this.setDefaultModelUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': this.csrfToken,
        },
        body: new URLSearchParams({ isDefault: String(target.checked) }),
      });
    }
  }

  private removeAuthenticityToken():void {
    const authenticityTokenInput = this.formTarget.querySelector('input[name="authenticity_token"]');
    if (this.isHTMLInputElement(authenticityTokenInput)) {
      authenticityTokenInput.remove();
    }
  }

  private isHTMLInputElement(element:EventTarget|Element|null):element is HTMLInputElement {
    return element !== null && element instanceof HTMLInputElement;
  }

  private trimFileExtension(fileName:string):string {
    const fileNameParts = fileName.split('.');
    return fileNameParts.slice(0, -1).join('.');
  }

  private get csrfToken():string {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') ?? '';
  }
}
