/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
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

/**
 * Stimulus controller for IFC conversion progress display
 * Handles visual feedback for real-time Turbo Stream updates
 */
export default class IfcConversionProgressController extends Controller {
  static targets = ['progressBar', 'statusText'];

  declare readonly progressBarTarget: HTMLElement;
  declare readonly statusTextTarget: HTMLElement;
  declare readonly hasProgressBarTarget: boolean;

  private animationTimeout?: number;

  connect() {
    // Remove the updating attribute after animation
    this.element.addEventListener('turbo:before-stream-render', this.beforeUpdate.bind(this));
  }

  disconnect() {
    if (this.animationTimeout) {
      window.clearTimeout(this.animationTimeout);
    }
  }

  beforeUpdate(event: Event) {
    // Add visual feedback when update is about to happen
    this.element.setAttribute('data-updating', 'true');

    // Remove the updating attribute after animation completes
    if (this.animationTimeout) {
      window.clearTimeout(this.animationTimeout);
    }

    this.animationTimeout = window.setTimeout(() => {
      this.element.removeAttribute('data-updating');
    }, 1000); // Match animation duration in CSS
  }

  /**
   * Manually refresh the progress (can be called from other controllers)
   */
  refresh() {
    // Trigger a visual pulse
    this.element.setAttribute('data-updating', 'true');
    setTimeout(() => {
      this.element.removeAttribute('data-updating');
    }, 1000);
  }

  /**
   * Check if conversion is complete
   */
  isComplete(): boolean {
    const status = this.element.getAttribute('data-status');
    return status === 'completed' || status === 'error';
  }

  /**
   * Get current progress percentage
   */
  getProgress(): number {
    const progress = this.element.getAttribute('data-progress');
    return progress ? parseInt(progress, 10) : 0;
  }
}
