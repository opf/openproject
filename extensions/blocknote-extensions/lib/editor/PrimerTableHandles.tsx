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

import { useEditorTranslation } from './editorTranslations';
import { ExtendButton, type ExtendButtonProps, TableCellButton, type TableCellButtonProps, TableHandle, type TableHandleProps, TableHandlesController } from '@blocknote/react';
import { GrabberIcon, PlusIcon, TriangleDownIcon } from '@primer/octicons-react';
import { PrimerActionMenus, PrimerMenuPortal, PrimerTableActionMenu } from './PrimerActionMenus';

function PrimerTableHandle(props:TableHandleProps) {
  const t = useEditorTranslation();
  const label = props.orientation === 'row' ? t('js.blocknote.row_actions') : t('js.blocknote.column_actions');
  return <PrimerTableActionMenu label={label}><TableHandle {...props}><GrabberIcon size={20} data-test="tableHandle" /></TableHandle></PrimerTableActionMenu>;
}

function PrimerCellHandle(props:TableCellButtonProps) {
  const t = useEditorTranslation();
  return <PrimerTableActionMenu label={t('js.blocknote.cell_actions')}><TableCellButton {...props}><TriangleDownIcon size={12} data-test="tableCellHandle" /></TableCellButton></PrimerTableActionMenu>;
}

function PrimerExtendButton(props:ExtendButtonProps) {
  const t = useEditorTranslation();
  const label = props.orientation === 'addOrRemoveRows' ? t('js.blocknote.extend_rows') : t('js.blocknote.extend_columns');
  return <PrimerActionMenus label={label}><ExtendButton {...props}><PlusIcon size={18} data-test="extendButton" /></ExtendButton></PrimerActionMenus>;
}

export function PrimerTableHandles() {
  return (
    <PrimerMenuPortal>
      <TableHandlesController tableHandle={PrimerTableHandle} tableCellHandle={PrimerCellHandle} extendButton={PrimerExtendButton} portalElement={document.body} />
    </PrimerMenuPortal>
  );
}
