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

import { TableHandlesExtension } from '@blocknote/core/extensions';
import { useEditorTranslation } from './editorTranslations';
import {
  AddCommentButton, AddTiptapCommentButton, BasicTextStyleButton, blockTypeSelectItems, BlockTypeSelect as BlockNoteBlockTypeSelect, type ComponentProps, CreateLinkButton, FileCaptionButton, FileDeleteButton, FileDownloadButton, FilePreviewButton, FileRenameButton, FileReplaceButton, NestBlockButton,
  PortalElementOverride, preventFocusOnTap, TableCellMergeButton, TextAlignButton, UnnestBlockButton,
  useBlockNoteEditor, useEditorState, usePortalElement, useUIMode,
} from '@blocknote/react';
import { OpenProjectFormattingToolbar } from '../components/FormattingToolbar';
import {
  BoldIcon, HeadingIcon, TriangleRightIcon, MoveToStartIcon, MoveToEndIcon, FoldIcon, ThreeBarsIcon, CodeIcon, CommentIcon, DownloadIcon, EyeIcon, ItalicIcon, LinkIcon, ListOrderedIcon, ListUnorderedIcon,
  NoteIcon, PencilIcon, QuoteIcon, StrikethroughIcon, TasklistIcon, TriangleDownIcon, TrashIcon, TypographyIcon,
} from '@primer/octicons-react';
import { ActionBar, ActionList, ActionMenu, Button, IconButton, PortalContext, registerPortalRoot, Stack } from '@primer/react';
import { PrimerReplaceButton } from './PrimerFilePanel';
import { PrimerToolbarForm } from './PrimerToolbarForm';
import { CloseTouchMenu, PrimerActionMenus, PrimerMenuPortal, TouchToolbarMenu } from './PrimerActionMenus';
import { Children, createContext, isValidElement, type ReactElement, type ReactNode, useContext, useLayoutEffect, useMemo } from 'react';

type Toolbar = ComponentProps['FormattingToolbar'];

const InActionBar = createContext(false);
const actionButtons = [TextAlignButton, NestBlockButton, UnnestBlockButton, TableCellMergeButton];

const ToolbarIcon = createContext<ReactElement | null>(null);
const styles:Partial<Record<string, typeof BoldIcon>> = { bold: BoldIcon, italic: ItalicIcon, strike: StrikethroughIcon, code: CodeIcon };
const blockIcons:Partial<Record<string, typeof BoldIcon>> = {
  heading: HeadingIcon, toggleListItem: TriangleRightIcon, paragraph: TypographyIcon, quote: QuoteIcon, bulletListItem: ListUnorderedIcon, numberedListItem: ListOrderedIcon, checkListItem: TasklistIcon,
};
const buttons = new Map<ReactElement['type'], typeof BoldIcon>([
  [NestBlockButton, MoveToEndIcon], [UnnestBlockButton, MoveToStartIcon],
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

function MergeIcon() {
  const editor = useBlockNoteEditor();
  const direction = useEditorState({ editor, selector: ({ editor }) => {
    const block = editor.getSelection()?.blocks[0] ?? editor.getTextCursorPosition().block;
    return block.type === 'table' ? editor.getExtension(TableHandlesExtension)?.getMergeDirection(block) : undefined;
  } });
  return <FoldIcon className={direction === 'horizontal' ? 'op-blocknote-merge-horizontal' : undefined} />;
}

function renderControl(control:ReactNode) {
  if (!isValidElement<{ basicTextStyle?:string, textAlignment?:'left' | 'center' | 'right' | 'justify', items?:unknown }>(control)) return control;
  if (control.type === BlockNoteBlockTypeSelect && !control.props.items) return <PrimerBlockTypeSelect key={control.key} />;
  if (control.type === FileReplaceButton) return <PrimerReplaceButton key={control.key} />;

  if (control.type === BasicTextStyleButton && control.props.basicTextStyle === 'underline') {
    return <ToolbarIcon.Provider key={control.key} value={<TypographyIcon className="op-blocknote-underline-icon" />}>{control}</ToolbarIcon.Provider>;
  }
  if (control.type === TableCellMergeButton) {
    return <ToolbarIcon.Provider key={control.key} value={<MergeIcon />}>{control}</ToolbarIcon.Provider>;
  }
  if (control.type === TextAlignButton) {
    return <ToolbarIcon.Provider key={control.key} value={<ThreeBarsIcon data-text-alignment={control.props.textAlignment} />}>{control}</ToolbarIcon.Provider>;
  }
  const Icon = control.type === BasicTextStyleButton && control.props.basicTextStyle
    ? styles[control.props.basicTextStyle] : buttons.get(control.type);
  if (!Icon) return control;
  const live = control.type === FileCaptionButton || control.type === FileRenameButton;
  return (
    <ToolbarIcon.Provider key={control.key} value={<Icon />}>
      {live || control.type === CreateLinkButton ? <PrimerToolbarForm live={live}>{control}</PrimerToolbarForm> : control}
    </ToolbarIcon.Provider>
  );
}

function ToolbarRoot({ className, children, onMouseEnter, onMouseLeave }:Toolbar['Root']) {
  const t = useEditorTranslation();
  const portalElement = usePortalElement();
  const { portalContainerName } = useContext(PortalContext);
  useLayoutEffect(() => {
    if (!portalElement || !portalContainerName) return undefined;
    registerPortalRoot(portalElement, portalContainerName);
    return () => registerPortalRoot(document.body, portalContainerName);
  }, [portalElement, portalContainerName]);

  const mobile = useUIMode() === 'mobile';
  const label = t('js.blocknote.formatting_toolbar');
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
  const t = useEditorTranslation();
  const overrideIcon = useContext(ToolbarIcon);
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
        icon={overrideIcon ?? icon}
        aria-label={isSelected ? t('js.blocknote.active_format', { format: name }) : name}
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
      icon={overrideIcon ?? icon}
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
  const t = useEditorTranslation();
  const selectedItem = items.find((item) => item.isSelected);
  if (!selectedItem) return null;
  const label = `${t('js.blocknote.block_type')}: ${selectedItem.text}`;
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
