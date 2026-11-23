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
import { BlockNoteViewRaw, type Components, useDictionary } from '@blocknote/react';
import { ActionList, Button, Spinner } from '@primer/react';
import { primerMenu, primerSideMenu, primerTableHandle } from './PrimerActionMenus';
import { primerPanel } from './PrimerFilePanel';
import { primerFormattingToolbar } from './PrimerFormattingToolbar';
import { primerLinkToolbar } from './PrimerLinkToolbar';
import { primerForm, primerPopover } from './PrimerToolbarForm';

function Loading() {
  const t = useEditorTranslation();
  return <Spinner size="small" srText={t('js.label_loading')} />;
}

const Comment:Components['Comments']['Comment'] = ({ className, authorInfo, timeString, edited, actions, showActions, children }) => {
  const dict = useDictionary();
  return (
    <article className={className}>
      <header>{authorInfo === 'loading' ? <Loading /> : authorInfo.username} <time>{timeString}</time> {edited && dict.comments.edited}</header>
      {showActions !== false && actions}
      {children}
    </article>
  );
};

export const primerEditorComponents = {
  FormattingToolbar: primerFormattingToolbar,
  LinkToolbar: { ...primerLinkToolbar, Select: primerFormattingToolbar.Select },
  FilePanel: primerPanel,
  SideMenu: primerSideMenu,
  TableHandle: primerTableHandle,
  Generic: {
    Menu: primerMenu,
    Form: primerForm,
    Popover: primerPopover,
    Toolbar: primerFormattingToolbar,
    Badge: {
      Root: ({ text, icon, mainTooltip, isSelected, onClick, ...props }) => (
        <Button {...props} size="small" title={mainTooltip} aria-pressed={isSelected} onClick={onClick}>{icon}{text}</Button>
      ),
      Group: props => <div {...props} />,
    },
  },
  SuggestionMenu: {
    Root: props => <ActionList {...props} role="listbox" disableFocusZone />,
    Item: ({ item, isSelected, onClick, ...props }) => (
      <ActionList.Item {...props} role="option" aria-selected={isSelected} onSelect={onClick}>
        {item.icon && <ActionList.LeadingVisual>{item.icon}</ActionList.LeadingVisual>}
        {item.title}
        {item.subtext && <ActionList.Description variant="block">{item.subtext}</ActionList.Description>}
        {item.badge && <ActionList.TrailingVisual>{item.badge}</ActionList.TrailingVisual>}
      </ActionList.Item>
    ),
    EmptyItem: props => <li {...props} role="presentation" />,
    Label: props => <ActionList.GroupHeading {...props} />,
    Loader: Loading,
  },
  GridSuggestionMenu: {
    Root: ({ columns, ...props }) => <div {...props} role="listbox" style={{ display: 'grid', gridTemplateColumns: `repeat(${columns}, 1fr)` }} />,
    Item: ({ item, isSelected, ...props }) => <Button {...props} role="option" aria-selected={isSelected}>{item.icon ?? item.id}</Button>,
    EmptyItem: ({ children, className }) => <div className={className}>{children}</div>,
    Loader: Loading,
  },
  AttributionTooltip: {
    Root: ({ markClassName, className, backgroundColor, children }) => (
      <span className={[className, markClassName].filter(Boolean).join(' ')} style={markClassName ? undefined : { backgroundColor }}>{children}</span>
    ),
  },
  Comments: {
    Card: ({ headerText, selected, children, ...props }) => <section {...props} data-selected={selected}>{headerText && <header>{headerText}</header>}{children}</section>,
    CardSection: props => <div {...props} />,
    ExpandSectionsPrompt: props => <div {...props} />,
    Editor: props => <BlockNoteViewRaw {...props} formattingToolbar={false} sideMenu={false} slashMenu={false} />,
    Comment,
  },
  Versioning: {
    Sidebar: props => <aside {...props} />,
    Snapshot: ({ children, selected, comparing, onClick, actions, className }) => (
      <div className={className} data-comparing={comparing}><Button onClick={onClick} aria-pressed={selected}>{children}</Button>{actions}</div>
    ),
  },
} satisfies Components;
