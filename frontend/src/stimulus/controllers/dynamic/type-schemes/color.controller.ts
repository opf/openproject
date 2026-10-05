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

const PALETTE = 'palette';
const CUSTOM = 'custom';

export default class ColorController extends Controller<HTMLElement> {
  static targets = ['mode', 'palette', 'custom', 'select', 'picker', 'swatch'];

  static values = {
    mode: { type: String, default: PALETTE },
    colors: { type: Object, default: {} },
  };

  declare readonly modeTargets:HTMLInputElement[];

  declare readonly hasPaletteTarget:boolean;

  declare readonly paletteTarget:HTMLElement;

  declare readonly hasCustomTarget:boolean;

  declare readonly customTarget:HTMLElement;

  declare readonly hasSelectTarget:boolean;

  declare readonly selectTarget:HTMLInputElement;

  declare readonly hasPickerTarget:boolean;

  declare readonly pickerTarget:HTMLInputElement;

  declare readonly hasSwatchTarget:boolean;

  declare readonly swatchTarget:HTMLElement;

  declare modeValue:string;

  declare readonly colorsValue:Record<string,string>;

  connect() {
    this.modeValue = this.checkedMode();
    this.apply();
  }

  modeChanged() {
    this.modeValue = this.checkedMode();
    this.apply();
  }

  selectChanged() {
    if (this.modeValue === PALETTE) { this.paint(this.selectedHex()); }
  }

  pickerChanged() {
    if (this.modeValue === CUSTOM && this.hasPickerTarget) { this.paint(this.pickerTarget.value); }
  }

  private checkedMode():string {
    return this.modeTargets.find((radio) => radio.checked)?.value ?? PALETTE;
  }

  private apply() {
    const palette = this.modeValue !== CUSTOM;

    if (this.hasPaletteTarget) { this.paletteTarget.hidden = !palette; }
    if (this.hasCustomTarget) { this.customTarget.hidden = palette; }
    if (this.hasSelectTarget) { this.selectTarget.disabled = !palette; }
    if (this.hasPickerTarget) { this.pickerTarget.disabled = palette; }

    const hex = palette
      ? this.selectedHex()
      : (this.hasPickerTarget ? this.pickerTarget.value : undefined);
    this.paint(hex);
  }

  private selectedHex():string|undefined {
    if (!this.hasSelectTarget) { return undefined; }

    const id = this.selectTarget.value;
    return id ? this.colorsValue[id] : undefined;
  }

  private paint(hex?:string) {
    if (!this.hasSwatchTarget || !hex) { return; }

    this.swatchTarget.style.backgroundColor = hex;
  }
}
