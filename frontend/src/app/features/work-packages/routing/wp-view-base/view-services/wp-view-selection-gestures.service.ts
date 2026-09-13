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
    const row = findSelectionOccurrence(rendered, workPackageId, classIdentifier);
    if (!row) return this.selection.getSelectedWorkPackageIds();
    if (modifiers.shiftKey) this.selection.rangeTo(row, rendered);
    else if (modifiers.ctrlKey || modifiers.metaKey) this.selection.toggleOccurrence(row);
    else this.selection.replaceOccurrence(row);
    return this.selection.getSelectedWorkPackageIds();
  }

  replace(workPackageId:string, rendered:RenderedWorkPackage[], classIdentifier?:string):void {
    const row = findSelectionOccurrence(rendered, workPackageId, classIdentifier);
    if (row) this.selection.replaceOccurrence(row);
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

export function findSelectionOccurrence(
  rows:RenderedWorkPackage[], id:string, classIdentifier?:string,
):RenderedWorkPackage|undefined {
  return rows.find((row) => row.workPackageId === id
    && (classIdentifier === undefined || row.classIdentifier === classIdentifier));
}
