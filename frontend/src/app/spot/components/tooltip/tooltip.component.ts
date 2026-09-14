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

import {
  Component,
  HostBinding,
  Input,
  ChangeDetectionStrategy,
} from '@angular/core';
import SpotDropAlignmentOption from '../../drop-alignment-options';

@Component({
  selector: 'spot-tooltip',
  templateUrl: './tooltip.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class SpotTooltipComponent {
  @HostBinding('class.spot-tooltip') public className = true;

  /**
   * Show a dark-gray version of the tooltip
   */
  @Input() @HostBinding('class.spot-tooltip_dark') public dark = false;

  /**
   * Whether the tooltip should be disabled.
   * In that case, hovering the trigger element will not do anything.
   */
  @Input() public disabled = false;

  /**
   * The alignment of the tooltip. There are twelve alignments in total. You can check which ones they are
   * from the `SpotDropAlignmentOption` Enum that is available in 'core-app/spot/drop-alignment-options'.
   */
  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomCenter;

  get alignmentClass():string {
    return `spot-tooltip--body_${this.alignment}`;
  }
}
