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

import { InjectionToken } from '@angular/core';
import type { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import type { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import type { DynamicIconName } from 'core-app/shared/components/primer/dynamic-icon-map';
import type { ActionMenuAlign } from 'core-common/contextual-action-menu';

export type OpContextMenuCloseReason = 'escape'|'action'|'outside'|'scroll';

/** What the Primer action menu needs from a handler: its items and where focus goes afterwards. */
export type OpActionMenuHost = Pick<OpContextMenuHandler, 'locals'|'onClose'>;

export interface OpActionMenuOptions {
  /** The element the menu anchors on; without it a pointer event's position is used. */
  anchor?:HTMLElement;
  align?:ActionMenuAlign;
}

export const OpContextMenuLocalsToken = new InjectionToken<OpContextMenuLocalsMap>('CONTEXT_MENU_LOCALS');

export interface OpContextMenuItem {
  disabled?:boolean;
  hidden?:boolean;
  icon?:string;
  /** Octicon name, rendered instead of the legacy `icon` class. */
  octicon?:DynamicIconName;
  postIcon?:string|null;
  postIconTitle?:string|null;
  href?:string;
  class?:string;
  ariaLabel?:string;
  linkText?:string;
  title?:string;
  divider?:boolean;
  isHeader?:boolean;
  onClick?:(event:MouseEvent) => boolean;
  /** Items of a submenu; the item itself then only opens it. */
  children?:OpContextMenuItem[];
  /** Renders the item as a `menuitemcheckbox` with this checked state. */
  checked?:boolean;
  /** Renders a `checked` item as a `menuitemradio`. */
  radio?:boolean;
  scheme?:'danger';
}

export interface OpContextMenuLocalsMap {
  items:OpContextMenuItem[];
  showAnchorRight?:boolean;
  contextMenuId?:string;
  label?:string;
  service?:OPContextMenuService;
  /* eslint-disable @typescript-eslint/no-explicit-any */
  [key:string]:any;
}
