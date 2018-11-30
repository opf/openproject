//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

import {Directive, ElementRef, Input} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';

import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {GridComponent} from "core-app/modules/grids/grid.component";

@Directive({
  selector: '[gridRowContextMenu]'
})
export class GridRowContextMenu extends OpContextMenuTrigger {
  @Input('gridRowContextMenu-grid') public grid:GridComponent;
  @Input('gridRowContextMenu-rowNumber') public rowNumber:number;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly I18n:I18nService) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:Event) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  public get locals() {
    return {
      //showAnchorRight: this.column && this.column.id !== 'id',
      contextMenuId: 'grid-context-menu',
      items: this.items
    };
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  //public positionArgs(evt:JQueryEventObject) {
  //  //let additionalPositionArgs = {
  //  //  of:  this.$element.find('.generic-table--sort-header-outer'),
  //  //};

  //  let position = super.positionArgs(evt);
  //  _.assign(position, additionalPositionArgs);

  //  return position;
  //}

  //protected get afterFocusOn():JQuery {
  //  return this.$element.find(`#${this.column.id}`);
  //}

  private buildItems() {
    let grid = this.grid;
    let rowNumber = this.rowNumber;

    // TODO: I18n
    this.items = [
      {
        linkText: "Add row before",
        onClick: () => {
          grid.addRow(rowNumber - 1);
          return true;
        }
      },
      {
        linkText: "Add row after",
        onClick: () => {
          grid.addRow(rowNumber);
          return true;
        }
      },
      {
        linkText: "Remove row",
        onClick: () => {
          grid.removeRow(rowNumber);
          return true;
        }
      }
    ];
  }
}

