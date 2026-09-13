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

import { Injectable, inject } from '@angular/core';
import { WorkPackageViewSelectionService } from './wp-view-selection.service';

export interface SelectionModifiers {
  shiftKey?:boolean;
  ctrlKey?:boolean;
  metaKey?:boolean;
}

@Injectable()
export class WorkPackageViewSelectionGesturesService {
  private readonly selection = inject(WorkPackageViewSelectionService);

  click(workPackageId:string, rendered:RenderedWorkPackage[], modifiers:SelectionModifiers, classIdentifier?:string):string[] {
    const toggle = Boolean(modifiers.ctrlKey) || Boolean(modifiers.metaKey);

    if (!modifiers.shiftKey && !toggle) {
      this.replace(workPackageId, rendered, classIdentifier);
    }

    if (modifiers.shiftKey) {
      this.selection.setMultiSelectionFrom(rendered, workPackageId, positionOf(rendered, workPackageId, classIdentifier));
    }

    if (toggle) {
      this.selection.toggleRow(workPackageId);
    }

    return this.selection.getSelectedWorkPackageIds();
  }

  replace(workPackageId:string, rendered:RenderedWorkPackage[], classIdentifier?:string):void {
    this.selection.setSelection(workPackageId, positionOf(rendered, workPackageId, classIdentifier));
  }

  contextMenu(workPackageId:string, rendered:RenderedWorkPackage[], classIdentifier?:string):void {
    if (!this.selection.isSelected(workPackageId)) {
      this.replace(workPackageId, rendered, classIdentifier);
    }
  }

  collapseTo(workPackageId:string, rendered:RenderedWorkPackage[], classIdentifier?:string):void {
    const selected = this.selection.getSelectedWorkPackageIds();
    const soleSelection = selected.length === 1 && selected[0] === workPackageId;

    if (selected.length > 0 && !soleSelection) {
      this.replace(workPackageId, rendered, classIdentifier);
    }
  }
}

function positionOf(rendered:RenderedWorkPackage[], workPackageId:string, classIdentifier?:string):number {
  return rendered.findIndex((row) => (classIdentifier === undefined
    ? row.workPackageId === workPackageId
    : row.classIdentifier === classIdentifier));
}
