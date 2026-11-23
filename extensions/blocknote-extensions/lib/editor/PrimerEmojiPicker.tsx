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
import { type DefaultReactGridSuggestionItem, type GridSuggestionMenuProps, useBlockNoteContext, useDictionary } from '@blocknote/react';
import { Button, Spinner } from '@primer/react';
import { memo, useEffect, useLayoutEffect, useRef } from 'react';

type EmojiGridProps = GridSuggestionMenuProps<DefaultReactGridSuggestionItem>;

const EmojiRow = memo(function EmojiRow({
  items, columns, start, selectedIndex, onItemClick,
}:Pick<EmojiGridProps, 'items' | 'columns' | 'selectedIndex' | 'onItemClick'> & { start:number }) {
  return (
    <div role="row" className="op-blocknote-emoji-row" style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}>
      {items.slice(start, start + columns).map((item, column) => (
        <Button key={item.id} id={`bn-suggestion-menu-item-${start + column}`} role="gridcell"
          aria-selected={start + column === selectedIndex} tabIndex={-1} variant="invisible" onClick={() => onItemClick?.(item)}>
          {item.id}
        </Button>
      ))}
    </div>
  );
});

export function PrimerEmojiPicker({ items, columns, selectedIndex, onItemClick, loadingState }:EmojiGridProps) {
  const t = useEditorTranslation();
  const dict = useDictionary();
  const setEditorProps = useBlockNoteContext()?.setContentEditableProps;
  const grid = useRef<HTMLDivElement>(null);
  useEffect(() => {
    setEditorProps?.((props) => ({ ...props, 'aria-haspopup': 'grid' }));
    return () => setEditorProps?.((props) => ({ ...props, 'aria-haspopup': 'listbox' }));
  }, [setEditorProps]);

  useLayoutEffect(() => {
    const viewport = grid.current;
    const cell = viewport?.querySelector('[aria-selected="true"]');
    if (!viewport || !cell) return;
    const bounds = viewport.getBoundingClientRect();
    const selected = cell.getBoundingClientRect();
    if (selected.top < bounds.top) viewport.scrollTop += selected.top - bounds.top;
    if (selected.bottom > bounds.bottom) viewport.scrollTop += selected.bottom - bounds.bottom;
  }, [selectedIndex, items]);

  const rows = [];
  for (let start = 0; start < items.length; start += columns) {
    const selectedInRow = selectedIndex !== undefined && selectedIndex >= start && selectedIndex < start + columns;
    rows.push(<EmojiRow key={start} items={items} start={start} columns={columns}
      selectedIndex={selectedInRow ? selectedIndex : undefined} onItemClick={onItemClick} />);
  }

  return (
    <div className="op-blocknote-emoji-picker">
      <div ref={grid} id="bn-suggestion-menu" role="grid" aria-label={dict.slash_menu.emoji.title} aria-busy={loadingState !== 'loaded'}>
        {rows}
      </div>
      {loadingState !== 'loaded' && <Spinner size="small" srText={t('js.label_loading')} />}
      {loadingState === 'loaded' && !items.length && <div role="status">{dict.suggestion_menu.no_items_title}</div>}
    </div>
  );
}
