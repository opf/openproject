/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2024 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { debounce } from 'lodash';

export default class PreviewProgressController extends Controller {
  static targets = [
    'form', 'progressInput',
  ];

  declare readonly progressInputTargets:HTMLInputElement[];
  declare readonly formTarget:HTMLFormElement;

  private debouncedPreview:(event:Event) => void;

  connect() {
    this.debouncedPreview = debounce((event:Event) => { void this.preview(event); }, 500);
    this.progressInputTargets.forEach((target) => target.addEventListener('input', this.debouncedPreview));
  }

  disconnect() {
    this.progressInputTargets.forEach((target) => target.removeEventListener('input', this.debouncedPreview));
  }

  async preview(event:Event) {
    const field = event.target as HTMLInputElement;
    const form = this.formTarget;
    const formData = new FormData(form) as unknown as undefined;
    const formParams = new URLSearchParams(formData);
    const wpParams = [
      ['work_package[remaining_hours]', formParams.get('work_package[remaining_hours]') || ''],
      ['work_package[estimated_hours]', formParams.get('work_package[estimated_hours]') || ''],
      ['field', field.name ?? 'estimatedTime'],
    ];

    const editUrl = `${form.action}/edit?${new URLSearchParams(wpParams).toString()}`;
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;

    if (turboFrame) {
      turboFrame.src = editUrl;
    }
  }
}
