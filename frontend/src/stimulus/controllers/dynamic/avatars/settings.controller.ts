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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { resizeImage } from 'core-app/shared/helpers/images/resizer';
import { decodeImageFile, updateObjectUrlPreview } from 'core-app/shared/helpers/images/object-url-preview';
import { setInputFiles } from 'core-app/shared/helpers/dom-helpers';

const SURROUNDING_SPACE = /^[\s\u0085]+|[\s\u0085]+$/gu;
const INVISIBLE_CODEPOINT = /[\p{Cc}\p{Cs}\p{Noncharacter_Code_Point}]|(?![\u200D\u{E0020}-\u{E007F}])\p{Cf}/u;
const MARK = /\p{M}/gu;
const MAX_CODEPOINTS_PER_CHARACTER = 16;
const MAX_MARKS_PER_CHARACTER = 4;

interface AvatarPreviewElement extends HTMLElement {
  avatarImageUrl:string;
  avatarFallbackImageUrl:string;
}

export default class AvatarSettingsController extends Controller<HTMLElement> {
  static targets = [
    'type', 'panel', 'text', 'color', 'file', 'uploadError', 'submit',
    'preview',
  ];

  static values = {
    initials: String,
    color: String,
    image: String,
    svgTemplate: String,
    maxLength: Number,
    gravatar: String,
    textLengthError: String,
    textInvalidError: String,
  };

  declare readonly typeTargets:HTMLInputElement[];
  declare readonly panelTargets:HTMLElement[];
  declare readonly textTarget:HTMLInputElement;
  declare readonly colorTarget:HTMLInputElement;
  declare readonly fileTarget:HTMLInputElement;
  declare readonly uploadErrorTarget:HTMLElement;
  declare readonly submitTarget:HTMLButtonElement;
  declare readonly previewTargets:HTMLElement[];
  declare readonly initialsValue:string;
  declare readonly colorValue:string;
  declare readonly imageValue:string;
  declare readonly svgTemplateValue:string;
  declare readonly maxLengthValue:number;
  declare readonly gravatarValue:string;
  declare readonly textLengthErrorValue:string;
  declare readonly textInvalidErrorValue:string;

  private imagePreview?:string;
  private resizing = false;
  private invalidImage = false;
  private imageGeneration = 0;

  connect() {
    this.update();
    void customElements.whenDefined('opce-principal').then(() => {
      if (this.element.isConnected) this.update();
    });
  }

  disconnect() {
    this.imageGeneration += 1;
    this.imagePreview = updateObjectUrlPreview(this.imagePreview, undefined);
  }

  update(event?:Event) {
    const selected = this.typeTargets.find((input) => input.checked);
    if (!selected) return;

    const type = selected.value;
    this.panelTargets.forEach((panel) => {
      const hidden = !panel.dataset.type?.split(' ').includes(type);
      panel.hidden = hidden;
      panel.querySelectorAll('input').forEach((input) => { input.disabled = hidden; });
    });
    const imageMissing = this.invalidImage || !(this.imagePreview ?? this.imageValue);
    this.submitTarget.disabled = this.resizing || (type === 'image' && imageMissing);

    const color = /^#(?:[\da-f]{3}|[\da-f]{6})$/i.test(this.colorTarget.value)
      ? this.colorTarget.value : this.colorValue;

    let text = this.initialsValue;
    this.textTarget.setCustomValidity('');
    if (type === 'initials') {
      const value = this.textTarget.value.replace(SURROUNDING_SPACE, '');
      const segments = Array.from(new Intl.Segmenter().segment(value), (segment) => segment.segment);
      const composing = event instanceof InputEvent && event.isComposing;
      this.textTarget.setCustomValidity(composing ? '' : this.textError(segments));
      text = segments.filter((segment) => this.visible(segment)).slice(0, this.maxLengthValue).join('') || this.initialsValue;
    }
    const source = type === 'image' ? this.imagePreview ?? this.imageValue
      : type === 'gravatar' ? this.gravatarValue : '';
    if (!customElements.get('opce-principal')) return;

    const fallbackImageUrl = this.fallbackImageUrl(text, color);
    this.previewTargets.forEach((preview) => {
      const component = preview.querySelector<AvatarPreviewElement>('opce-principal');
      if (!component) return;

      component.avatarFallbackImageUrl = fallbackImageUrl;
      component.avatarImageUrl = source || fallbackImageUrl;
    });
  }

  private textError(segments:string[]):string {
    if (!segments.every((segment) => this.visible(segment))) return this.textInvalidErrorValue;
    if (segments.length > this.maxLengthValue) return this.textLengthErrorValue;
    return '';
  }

  private visible(segment:string):boolean {
    return !INVISIBLE_CODEPOINT.test(segment)
      && Array.from(segment).length <= MAX_CODEPOINTS_PER_CHARACTER
      && (segment.match(MARK)?.length ?? 0) <= MAX_MARKS_PER_CHARACTER;
  }

  private fallbackImageUrl(text:string, color:string):string {
    const svg = new DOMParser().parseFromString(this.svgTemplateValue, 'image/svg+xml');
    const svgText = svg.querySelector('text')!;
    svgText.textContent = text;
    svgText.setAttribute('fill', this.textColorFor(color));
    svg.querySelector('rect')!.setAttribute('fill', color);
    return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(new XMLSerializer().serializeToString(svg))}`;
  }

  private textColorFor(color:string):string {
    if (!color.startsWith('#')) return '#ffffff';

    let hex = color.slice(1);
    if (hex.length === 3) hex = hex.split('').map((character) => character.repeat(2)).join('');
    const [red, green, blue] = hex.match(/../g)!.map((channel) => parseInt(channel, 16));
    return (red * 299 + green * 587 + blue * 114) / 1000 >= 150 ? '#1f2328' : '#ffffff';
  }

  randomizeColor() {
    const currentColor = this.colorTarget.value.toUpperCase();
    let color:string;
    do {
      color = `#${Math.floor(Math.random() * 0x1000000).toString(16).padStart(6, '0').toUpperCase()}`;
    } while (color === currentColor);

    this.colorTarget.value = color;
    this.colorTarget.dispatchEvent(new Event('input', { bubbles: true }));
  }

  chooseImage() {
    this.fileTarget.click();
  }

  async upload() {
    const file = this.fileTarget.files?.[0];
    if (!file) return;

    this.imageGeneration += 1;
    const generation = this.imageGeneration;
    this.invalidImage = false;
    this.resizing = true;
    this.uploadErrorTarget.hidden = true;
    this.update();
    try {
      if (!['image/jpeg', 'image/png', 'image/gif'].includes(file.type)) throw new Error('Invalid image');
      const image = await decodeImageFile(file);
      if (generation !== this.imageGeneration) return;

      const [, blob] = resizeImage(128, image);
      setInputFiles(this.fileTarget, new File([blob], file.name, { type: blob.type }));
      this.imagePreview = updateObjectUrlPreview(this.imagePreview, blob);
    } catch {
      if (generation !== this.imageGeneration) return;
      this.fileTarget.value = '';
      this.invalidImage = true;
      this.uploadErrorTarget.hidden = false;
    } finally {
      if (generation === this.imageGeneration) {
        this.resizing = false;
        this.update();
      }
    }
  }
}
