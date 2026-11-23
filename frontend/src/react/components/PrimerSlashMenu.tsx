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

import { DefaultReactSuggestionItem, SuggestionMenuProps, useDictionary } from '@blocknote/react';
import {
  CodeSquareIcon, FileIcon, HorizontalRuleIcon, ImageIcon, ListOrderedIcon, ListUnorderedIcon, QuoteIcon,
  SmileyIcon, TableIcon, TasklistIcon, TypographyIcon, UnmuteIcon, VideoIcon,
} from '@primer/octicons-react';
import { ActionList, Spinner } from '@primer/react';
import { KeybindingHint } from '@primer/react/experimental';
import { useEffect, useRef } from 'react';

const commandIcons:Partial<Record<string, typeof FileIcon>> = {
  audio: UnmuteIcon,
  bullet_list: ListUnorderedIcon,
  check_list: TasklistIcon,
  code_block: CodeSquareIcon,
  divider: HorizontalRuleIcon,
  emoji: SmileyIcon,
  file: FileIcon,
  image: ImageIcon,
  numbered_list: ListOrderedIcon,
  paragraph: TypographyIcon,
  quote: QuoteIcon,
  table: TableIcon,
  video: VideoIcon,
};

function commandIcon(item:DefaultReactSuggestionItem) {
  const Icon = 'key' in item && typeof item.key === 'string' ? commandIcons[item.key] : undefined;
  return Icon ? <Icon /> : item.icon;
}

export function PrimerSlashMenu({ items, selectedIndex, onItemClick, loadingState }:SuggestionMenuProps<DefaultReactSuggestionItem>) {
  const dictionary = useDictionary();
  const list = useRef<HTMLUListElement>(null);
  useEffect(() => {
    list.current?.querySelector('[aria-selected="true"]')?.scrollIntoView({ block: 'nearest' });
  }, [items, selectedIndex]);

  const groups = new Map<string | undefined, { item:DefaultReactSuggestionItem, index:number }[]>();
  items.forEach((item, index) => {
    const group = groups.get(item.group) ?? [];
    group.push({ item, index });
    groups.set(item.group, group);
  });

  return (
    <ActionList ref={list} id="bn-suggestion-menu" className="op-primer-slash-menu" role="listbox" disableFocusZone>
      {Array.from(groups, ([group, entries]) => (
        <ActionList.Group key={group} title={group}>
          {entries.map(({ item, index }) => (
            <ActionList.Item
              key={item.title}
              id={`bn-suggestion-menu-item-${index}`}
              role="option"
              aria-selected={index === selectedIndex}
              tabIndex={-1}
              onSelect={() => onItemClick?.(item)}
            >
              {item.icon && <ActionList.LeadingVisual>{commandIcon(item)}</ActionList.LeadingVisual>}
              {item.title}
              {item.subtext && <ActionList.Description variant="block">{item.subtext}</ActionList.Description>}
              {item.badge && (
                <ActionList.TrailingVisual>
                  <KeybindingHint keys={item.badge.replace(/^(⌘|Ctrl)-/, 'Mod-').replaceAll('-', '+')} />
                </ActionList.TrailingVisual>
              )}
            </ActionList.Item>
          ))}
        </ActionList.Group>
      ))}
      {loadingState !== 'loaded' && <li role="presentation"><Spinner size="small" /></li>}
      {loadingState === 'loaded' && !items.length && <li role="presentation">{dictionary.suggestion_menu.no_items_title}</li>}
    </ActionList>
  );
}
