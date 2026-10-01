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

export default class PDFExportSettingsController extends Controller {
  static targets = [
    'fields',
  ];

  declare readonly fieldsTargets:HTMLInputElement[];

  private silenceFormFields(element:HTMLElement, silence:boolean) {
    element.querySelectorAll('input, select').forEach((input:HTMLInputElement) => {
      input.disabled = silence;
    });
  }

  connect() {
    this.fieldsTargets.forEach((element:HTMLElement) => {
      if (element.classList.contains('d-none')) {
        this.silenceFormFields(element, true);
      }
    });
  }

  typeChanged({ params: { name } }:{ params:{ name:string } }) {
    this.fieldsTargets.forEach((element:HTMLElement) => {
      if (element.getAttribute('data-pdf-export-type') === name) {
        element.classList.remove('d-none');
        this.silenceFormFields(element, false);
      } else {
        element.classList.add('d-none');
        this.silenceFormFields(element, true);
      }
    });
  }
}
