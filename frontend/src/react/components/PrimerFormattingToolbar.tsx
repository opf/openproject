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

import {
  AddCommentButton, AddTiptapCommentButton, BasicTextStyleButton, blockTypeSelectItems, BlockTypeSelect as BlockNoteBlockTypeSelect, ComponentProps, CreateLinkButton, FileCaptionButton, FileDeleteButton, FileDownloadButton, FilePreviewButton, FileRenameButton, FileReplaceButton, NestBlockButton,
  PortalElementOverride, preventFocusOnTap, TableCellMergeButton, TextAlignButton, UnnestBlockButton,
  useBlockNoteEditor, usePortalElement, useUIMode,
} from '@blocknote/react';
import { OpenProjectFormattingToolbar } from '@openproject/blocknote-extensions';
import {
  BoldIcon, CodeIcon, CommentIcon, DownloadIcon, EyeIcon, ItalicIcon, LinkIcon, ListOrderedIcon, ListUnorderedIcon,
  NoteIcon, PencilIcon, QuoteIcon, StrikethroughIcon, TasklistIcon, TriangleDownIcon, TrashIcon, TypographyIcon,
} from '@primer/octicons-react';
import { ActionBar, ActionList, ActionMenu, Button, IconButton, PortalContext, registerPortalRoot, Stack } from '@primer/react';
import { PrimerReplaceButton } from './PrimerFilePanel';
import { PrimerToolbarForm } from './PrimerToolbarForm';
import { CloseTouchMenu, PrimerActionMenus, PrimerMenuPortal, TouchToolbarMenu } from './PrimerActionMenus';
import { Children, createContext, isValidElement, ReactElement, ReactNode, useContext, useLayoutEffect, useMemo } from 'react';

type Toolbar = ComponentProps['FormattingToolbar'];

const InActionBar = createContext(false);
const actionButtons = [TextAlignButton, NestBlockButton, UnnestBlockButton, TableCellMergeButton];

const ToolbarIcon = createContext<typeof BoldIcon | undefined>(undefined);
const styles:Partial<Record<string, typeof BoldIcon>> = { bold: BoldIcon, italic: ItalicIcon, strike: StrikethroughIcon, code: CodeIcon };
const blockIcons:Partial<Record<string, typeof BoldIcon>> = {
  paragraph: TypographyIcon, quote: QuoteIcon, bulletListItem: ListUnorderedIcon, numberedListItem: ListOrderedIcon, checkListItem: TasklistIcon,
};
const buttons = new Map<ReactElement['type'], typeof BoldIcon>([
  [FileCaptionButton, NoteIcon], [FileRenameButton, PencilIcon], [FileDeleteButton, TrashIcon], [FileDownloadButton, DownloadIcon],
  [FilePreviewButton, EyeIcon], [CreateLinkButton, LinkIcon], [AddCommentButton, CommentIcon], [AddTiptapCommentButton, CommentIcon],
]);

function PrimerBlockTypeSelect() {
  const editor = useBlockNoteEditor();
  const items = useMemo(() => blockTypeSelectItems(editor.dictionary).map((item) => {
    const Icon = blockIcons[item.type];
    return Icon ? { ...item, icon: () => <Icon /> } : item;
  }), [editor]);
  return <BlockNoteBlockTypeSelect items={items} />;
}

function renderControl(control:ReactNode) {
  if (!isValidElement<{ basicTextStyle?:string, items?:unknown }>(control)) return control;
  if (control.type === BlockNoteBlockTypeSelect && !control.props.items) return <PrimerBlockTypeSelect key={control.key} />;
  if (control.type === FileReplaceButton) return <PrimerReplaceButton key={control.key} />;

  const Icon = control.type === BasicTextStyleButton && control.props.basicTextStyle
    ? styles[control.props.basicTextStyle] : buttons.get(control.type);
  if (!Icon) return control;
  const live = control.type === FileCaptionButton || control.type === FileRenameButton;
  return (
    <ToolbarIcon.Provider key={control.key} value={Icon}>
      {live || control.type === CreateLinkButton ? <PrimerToolbarForm live={live}>{control}</PrimerToolbarForm> : control}
    </ToolbarIcon.Provider>
  );
}

function ToolbarRoot({ className, children, onMouseEnter, onMouseLeave }:Toolbar['Root']) {
  const portalElement = usePortalElement();
  const { portalContainerName } = useContext(PortalContext);
  useLayoutEffect(() => {
    if (!portalElement || !portalContainerName) return undefined;
    registerPortalRoot(portalElement, portalContainerName);
    return () => registerPortalRoot(document.body, portalContainerName);
  }, [portalElement, portalContainerName]);

  const mobile = useUIMode() === 'mobile';
  const label = window.I18n.t('js.blocknote.formatting_toolbar');
  const controls = Children.toArray(children);
  const isAction = (control:typeof controls[number]) => isValidElement(control) && actionButtons.some((type) => type === control.type);
  const isStyle = (control:typeof controls[number]) => isValidElement(control) && control.type === BasicTextStyleButton;
  const isPicker = (control:typeof controls[number]) => isValidElement(control) && control.type === BlockNoteBlockTypeSelect;

  return (
    <Stack
      role={mobile ? 'toolbar' : 'group'}
      aria-label={label}
      className={`${className} op-primer-formatting-toolbar`}
      direction="horizontal"
      align="center"
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
    >
      <PrimerActionMenus returnFocusToEditor>
        {mobile ? controls.map(renderControl) : (
          <>
            {controls.filter(isPicker).map(renderControl)}
            <ActionBar flush size="medium" gap="none" aria-label={label}>
              <InActionBar.Provider value>
                <ActionBar.Group>{controls.filter(isStyle).map(renderControl)}</ActionBar.Group>
                {controls.filter(isAction).map(renderControl)}
              </InActionBar.Provider>
            </ActionBar>
            {controls.filter((control) => !isPicker(control) && !isAction(control) && !isStyle(control)).map(renderControl)}
          </>
        )}
      </PrimerActionMenus>
    </Stack>
  );
}

function ToolbarButton({
  children, icon, isSelected, isDisabled, label, mainTooltip, secondaryTooltip, variant, ...rest
}:Toolbar['Button']) {
  const Icon = useContext(ToolbarIcon);
  const inActionBar = useContext(InActionBar);
  const editor = useBlockNoteEditor();
  const props = {
    ...rest,
    variant: 'invisible' as const,
    size: 'medium' as const,
    disabled: isDisabled,
    'aria-pressed': isSelected,
    'data-compact': variant === 'compact' || undefined,
    onMouseDown: preventFocusOnTap,
  };

  if (inActionBar) {
    const name = mainTooltip ?? label ?? '';
    return (
      <ActionBar.IconButton
        {...props}
        icon={Icon ? <Icon /> : icon}
        aria-label={isSelected ? window.I18n.t('js.blocknote.active_format', { format: name }) : name}
        keybindingHint={secondaryTooltip?.replace(/^(⌘|Ctrl)\+/, 'Mod+')}
        onClick={(event) => {
          const fromOverflow = event.currentTarget.getAttribute('role') === 'menuitem';
          rest.onClick?.(event);
          if (fromOverflow) requestAnimationFrame(() => editor.focus());
        }}
      />
    );
  }

  if (children) {
    return <Button {...props} aria-label={label} title={mainTooltip}>{children}</Button>;
  }

  return (
    <IconButton
      {...props}
      icon={Icon ? <Icon /> : icon}
      aria-label={mainTooltip ?? label ?? ''}
      keybindingHint={secondaryTooltip?.replace(/^(⌘|Ctrl)\+/, 'Mod+')}
    />
  );
}

function BlockChoices({ items, label }:Pick<Toolbar['Select'], 'items'> & { label:string }) {
  const close = useContext(CloseTouchMenu);
  return (
    <ActionList selectionVariant="single" role="menu" aria-label={label} disableFocusZone={!!close}>
      {items.map((item) => (
        <ActionList.Item key={item.text} role="menuitemradio" selected={item.isSelected} disabled={item.isDisabled} onSelect={() => { item.onClick(); close?.(); }}>
          <ActionList.LeadingVisual>{item.icon}</ActionList.LeadingVisual>
          {item.text}
        </ActionList.Item>
      ))}
    </ActionList>
  );
}

function BlockTypeSelect({ items, isDisabled, preventFocusOnOpen }:Toolbar['Select']) {
  const selectedItem = items.find((item) => item.isSelected);
  if (!selectedItem) return null;
  const label = `${window.I18n.t('js.blocknote.block_type')}: ${selectedItem.text}`;
  const choices = <BlockChoices items={items} label={label} />;
  const anchor = (
    <Button size="small" variant="invisible" disabled={isDisabled} aria-label={label} onMouseDown={preventFocusOnTap}
      trailingAction={TriangleDownIcon}>
      {selectedItem.text}
    </Button>
  );
  if (preventFocusOnOpen) return <TouchToolbarMenu anchor={anchor}>{choices}</TouchToolbarMenu>;
  return (
    <ActionMenu>
      <ActionMenu.Anchor>{anchor}</ActionMenu.Anchor>
      <ActionMenu.Overlay className="op-blocknote-action-menu" maxHeight="medium" overflow="auto">{choices}</ActionMenu.Overlay>
    </ActionMenu>
  );
}

export const primerFormattingToolbar = { Root: ToolbarRoot, Button: ToolbarButton, Select: BlockTypeSelect };

export function PrimerFormattingToolbar() {
  return (
    <PortalElementOverride target={document.body}>
      <PrimerMenuPortal>
        <OpenProjectFormattingToolbar />
      </PrimerMenuPortal>
    </PortalElementOverride>
  );
}
