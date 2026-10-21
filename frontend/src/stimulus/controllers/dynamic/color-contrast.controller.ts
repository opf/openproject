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
import { announce } from '@primer/live-region-element';
import { composite, computedColor, contrastRatio, formatContrastRatio, normalizeHex, toHex } from '../../helpers/color-contrast';

export default class ColorContrastController extends Controller {
  static targets = ['hexcode', 'preview', 'outdated', 'card', 'summary'];

  declare readonly hexcodeTarget:HTMLInputElement;
  declare readonly previewTarget:HTMLElement;
  declare readonly outdatedTarget:HTMLElement;
  declare readonly cardTargets:HTMLElement[];
  declare readonly summaryTarget:HTMLElement;

  private lastChecked:string|null = null;

  markOutdated():void {
    const unchanged = normalizeHex(this.hexcodeTarget.value) === this.lastChecked;
    this.outdatedTarget.hidden = this.previewTarget.hidden || unchanged;
    this.setInvalid(false);
  }

  check():void {
    const hex = normalizeHex(this.hexcodeTarget.value);
    this.setInvalid(hex === null);
    if (!hex) return;

    this.lastChecked = hex;
    this.previewTarget.hidden = false;
    this.outdatedTarget.hidden = true;
    const channels = hex.slice(1).match(/../g)!.map((channel) => parseInt(channel, 16));
    // Mirrors Colors::HexColor#perceived_lightness (app/models/colors/hex_color.rb),
    // including the four-place rounding; keep both in step.
    const lightness = ((channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722) / 255).toFixed(4);
    const results = this.cardTargets.map((card) => {
      const sample = card.querySelector<HTMLElement>('[data-color-contrast-target="sample"]')!;
      sample.style.setProperty('--hl-color', hex);
      sample.style.setProperty('--hl-perceived-lightness', lightness);
      return this.evaluate(sample, card);
    });
    this.summaryTarget.textContent = I18n.t('js.colors.contrast.summary', { passed: results.filter(Boolean).length });
  }

  private setInvalid(invalid:boolean):void {
    if (invalid) {
      this.setError(this.hexcodeTarget.dataset.invalidMessage!);
      this.previewTarget.hidden = true;
    } else {
      this.clearError();
    }
  }

  // Stand-ins for the missing PrimerColorInputElement validation API:
  // https://community.openproject.org/wp/DREAM-918
  private setError(message:string):void {
    this.validationMessageElement.textContent = message;
    this.validationElement.hidden = false;
    this.hexcodeTarget.setAttribute('invalid', 'true');
    this.hexcodeTarget.setAttribute('aria-invalid', 'true');
    void announce(message, { politeness: 'assertive' });
  }

  private clearError():void {
    this.validationElement.hidden = true;
    this.validationMessageElement.replaceChildren();
    this.hexcodeTarget.removeAttribute('invalid');
    this.hexcodeTarget.removeAttribute('aria-invalid');
  }

  private get validationElement():HTMLElement {
    return this.hexcodeTarget.closest('.FormControl')!.querySelector<HTMLElement>('.FormControl-inlineValidation')!;
  }

  private get validationMessageElement():HTMLElement {
    return this.validationElement.querySelector<HTMLElement>('span:not(.FormControl-inlineValidation--visual)')!;
  }

  private evaluate(sample:HTMLElement, card:HTMLElement):boolean {
    const style = getComputedStyle(sample);
    const surface = sample.closest('.color-contrast--surface')!;
    const surfaceColor = computedColor(getComputedStyle(surface).backgroundColor);
    const background = computedColor(style.backgroundColor);
    const effectiveBackground = composite(background, surfaceColor);
    const foreground = composite(computedColor(style.color), effectiveBackground);
    const ratio = contrastRatio(foreground, effectiveBackground);
    const values:Record<string, string> = {
      foreground: toHex(foreground),
      background: toHex(effectiveBackground),
      ratio: formatContrastRatio(ratio),
    };
    Object.entries(values).forEach(([name, value]) => {
      card.querySelector<HTMLElement>(`[data-contrast-value="${name}"]`)!.textContent = value;
    });
    const pass = ratio >= 4.5;
    card.querySelectorAll<HTMLElement>('[data-contrast-verdict]').forEach((verdict) => {
      verdict.hidden = verdict.dataset.contrastVerdict !== (pass ? 'pass' : 'fail');
    });
    return pass;
  }
}
