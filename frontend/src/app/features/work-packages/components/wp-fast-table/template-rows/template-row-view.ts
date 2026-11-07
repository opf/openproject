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

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { TableDragActionsRegistryService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { rowHighlightClasses } from '../builders/highlighting/row-highlight-render-pass';
import type { PrimaryRenderPass } from '../builders/primary-render-pass';
import type { TemplateRowView } from './template-row';

export function templateRowView(pass:PrimaryRenderPass):TemplateRowView {
  const { injector, rowBuilder, workPackageTable } = pass;
  const { configuration, editing } = workPackageTable;
  const dragActions = configuration.dragAndDropEnabled
    ? injector.get(TableDragActionsRegistryService).get(injector)
    : null;

  return {
    columns: rowBuilder.renderedColumns,
    rowHeader: rowBuilder.rowHeaderColumn,
    rowClasses: (workPackage) => rowHighlightClasses(injector.get(WorkPackageViewHighlightingService), workPackage),
    actions: (workPackage) => (configuration.actionsColumnEnabled
      ? injector.get(OpTableActionsService).actionsFor(workPackage)
      : null),
    contextMenuLabel: injector.get(I18nService).t('js.label_open_context_menu'),
    canDrag: (workPackage) => dragActions?.canPickup(workPackage) ?? null,
    placeholder: workPackageTable.renderPlaceholderRow,
    buildCell: ({ workPackage, level, relation }, column) => (relation
      ? pass.relations.relationRowBuilder.buildCell(workPackage, column)
      : rowBuilder.buildTemplateCell(workPackage, column, level - 1)),
    isEditing: (workPackage, column, cell) => {
      const field = editing.forms[workPackage.id!]?.activeFields[column.id];
      return field?.element !== undefined && cell.contains(field.element);
    },
  };
}
