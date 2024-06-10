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
import Idiomorph from 'idiomorph/dist/idiomorph.cjs';

interface TurboBeforeFrameRenderEventDetail {
  render:(currentElement:HTMLElement, newElement:HTMLElement) => void;
}

export default class PreviewProgressController extends Controller {
  static targets = ['form', 'progressInput'];

  declare readonly progressInputTargets:HTMLInputElement[];
  declare readonly formTarget:HTMLFormElement;

  private debouncedPreview:(event:Event) => void;
  private frameMorphRenderer:(event:CustomEvent<TurboBeforeFrameRenderEventDetail>) => void;
  private activeElement:HTMLInputElement|null = null;
  private initialMorphDone:boolean = false;

  connect() {
    this.debouncedPreview = debounce((event:Event) => { void this.preview(event); }, 100);
    this.frameMorphRenderer = (event:CustomEvent<TurboBeforeFrameRenderEventDetail>) => {
      event.detail.render = (currentElement:HTMLElement, newElement:HTMLElement) => {
        Idiomorph.morph(currentElement, newElement, { ignoreActiveValue: this.initialMorphDone });
      };
    };

    this.progressInputTargets.forEach((target) => {
      target.addEventListener('blur', this.handleBlur.bind(this));
      target.addEventListener('focus', this.handleFocus.bind(this));
      target.addEventListener('input', this.debouncedPreview);
    });

    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;
    turboFrame.addEventListener('turbo:before-frame-render', this.frameMorphRenderer);
    this.checkInitialFocus();
  }

  disconnect() {
    this.progressInputTargets.forEach((target) => {
      target.removeEventListener('blur', this.handleBlur.bind(this));
      target.removeEventListener('focus', this.handleFocus.bind(this));
      target.removeEventListener('input', this.debouncedPreview);
    });
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;
    turboFrame.removeEventListener('turbo:before-frame-render', this.frameMorphRenderer);
  }

  handleFocus(event:Event) {
    this.activeElement = event.target as HTMLInputElement;
    this.initialMorphDone = false;
    void this.preview(event);
  }

  handleBlur(event:Event) {
    this.activeElement = null;
    this.initialMorphDone = true;
    void this.preview(event);
  }

  checkInitialFocus() {
    const initiallyFocusedElement = this.progressInputTargets.find((target) => target === document.activeElement);
    if (initiallyFocusedElement) {
      this.activeElement = initiallyFocusedElement;
      this.initialMorphDone = false;
      this.activeElement.focus();
    }
  }

  async preview(event:Event) {
    if (event.type === 'input') {
      this.initialMorphDone = true;
    }

    const field = event.target as HTMLInputElement;
    const form = this.formTarget;
    const formData = new FormData(form) as unknown as undefined;
    const formParams = new URLSearchParams(formData);
    const wpParams = [
      ['work_package[remaining_hours]', formParams.get('work_package[remaining_hours]') || ''],
      ['work_package[estimated_hours]', formParams.get('work_package[estimated_hours]') || ''],
      ['work_package[status_id]', formParams.get('work_package[status_id]') || ''],
      ['field', (event.type === 'blur' ? '' : field.name ?? 'estimatedTime')],
      ['work_package[remaining_hours_touched]', formParams.get('work_package[remaining_hours_touched]') || ''],
      ['work_package[estimated_hours_touched]', formParams.get('work_package[estimated_hours_touched]') || ''],
      ['work_package[status_id_touched]', formParams.get('work_package[status_id_touched]') || ''],
      ['format_durations', 'true'],
    ];

    const wpPath = this.ensureValidPathname(form.action);

    const editUrl = `${wpPath}/edit?${new URLSearchParams(wpParams).toString()}`;
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;

    if (turboFrame) {
      turboFrame.src = editUrl;
    }
  }

  private ensureValidPathname(formAction:string):string {
    const wpPath = new URL(formAction);

    if (wpPath.pathname.endsWith('/work_packages/progress')) {
      wpPath.pathname = wpPath.pathname.replace('/work_packages/progress', '/work_packages/new/progress');
    }

    return wpPath.toString();
  }
}
