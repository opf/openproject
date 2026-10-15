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

export default class AvatarSettingsController extends Controller<HTMLElement> {
  static targets = [
    'type', 'panel', 'text', 'color', 'swatch', 'file', 'uploadError', 'submit',
    'previewImage', 'previewSvg',
  ];

  static values = {
    initials: String,
    color: String,
    image: String,
    svgTemplate: String,
    maxLength: Number,
    gravatar: String,
    textLengthError: String,
  };

  declare readonly typeTargets:HTMLInputElement[];
  declare readonly panelTargets:HTMLElement[];
  declare readonly textTarget:HTMLInputElement;
  declare readonly colorTarget:HTMLInputElement;
  declare readonly swatchTargets:HTMLButtonElement[];
  declare readonly fileTarget:HTMLInputElement;
  declare readonly uploadErrorTarget:HTMLElement;
  declare readonly submitTarget:HTMLButtonElement;
  declare readonly previewImageTargets:HTMLImageElement[];
  declare readonly previewSvgTargets:SVGSVGElement[];
  declare readonly initialsValue:string;
  declare readonly colorValue:string;
  declare readonly imageValue:string;
  declare readonly svgTemplateValue:string;
  declare readonly maxLengthValue:number;
  declare readonly gravatarValue:string;
  declare readonly textLengthErrorValue:string;

  private imagePreview?:string;
  private failedImageSource?:string;
  private resizing = false;
  private invalidImage = false;
  private imageGeneration = 0;

  connect() {
    this.update();
  }

  disconnect() {
    this.imageGeneration += 1;
    if (this.imagePreview) URL.revokeObjectURL(this.imagePreview);
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
    this.submitTarget.disabled = this.resizing || (type === 'image' && this.invalidImage);

    const color = /^#(?:[\da-f]{3}|[\da-f]{6})$/i.test(this.colorTarget.value)
      ? this.colorTarget.value : this.colorValue;
    this.swatchTargets.forEach((button) => {
      button.setAttribute('aria-pressed', String(button.dataset.color === this.colorTarget.value.toUpperCase()));
    });

    let text = this.initialsValue;
    this.textTarget.setCustomValidity('');
    if (type === 'initials') {
      const value = this.textTarget.value.trim();
      const segments = Array.from(new Intl.Segmenter().segment(value), (segment) => segment.segment);
      const composing = event instanceof InputEvent && event.isComposing;
      this.textTarget.setCustomValidity(!composing && segments.length > this.maxLengthValue ? this.textLengthErrorValue : '');
      text = segments.slice(0, this.maxLengthValue).join('') || this.initialsValue;
    }
    const source = type === 'image' ? this.imagePreview ?? this.imageValue
      : type === 'gravatar' ? this.gravatarValue : '';
    const showImage = Boolean(source) && source !== this.failedImageSource;
    this.previewSvgTargets.forEach((svg) => {
      svg.querySelector('text')!.textContent = text;
      svg.querySelector('rect')!.setAttribute('fill', color);
      svg.classList.toggle('d-none', showImage);
    });
    this.previewImageTargets.forEach((img) => {
      img.hidden = !showImage;
      if (showImage && img.getAttribute('src') !== source) img.src = source;
    });
  }

  imageFailed(event:Event) {
    this.failedImageSource = (event.currentTarget as HTMLImageElement).getAttribute('src') ?? '';
    this.update();
  }

  setColor(event:Event) {
    this.colorTarget.value = (event.currentTarget as HTMLElement).dataset.color ?? '';
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
    const source = URL.createObjectURL(file);
    try {
      if (!['image/jpeg', 'image/png', 'image/gif'].includes(file.type)) throw new Error('Invalid image');
      const image = new Image();
      image.src = source;
      await image.decode();
      if (generation !== this.imageGeneration) return;

      const [, blob] = resizeImage(128, image);
      const transfer = new DataTransfer();
      transfer.items.add(new File([blob], file.name, { type: blob.type }));
      this.fileTarget.files = transfer.files;
      if (this.imagePreview) URL.revokeObjectURL(this.imagePreview);
      this.imagePreview = URL.createObjectURL(blob);
    } catch {
      if (generation !== this.imageGeneration) return;
      this.fileTarget.value = '';
      this.invalidImage = true;
      this.uploadErrorTarget.hidden = false;
    } finally {
      URL.revokeObjectURL(source);
      if (generation === this.imageGeneration) {
        this.resizing = false;
        this.update();
      }
    }
  }
}
