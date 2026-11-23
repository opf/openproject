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

import { type ComponentProps, preventFocusOnTap, useBlockNoteEditor, useDictionary } from '@blocknote/react';
import { GrabberIcon, PlusIcon } from '@primer/octicons-react';
import { ActionList, ActionMenu, AnchoredOverlay, IconButton, PortalContext, registerPortalRoot } from '@primer/react';
import { Children, cloneElement, createContext, forwardRef, Fragment, isValidElement, type PropsWithChildren, type ReactElement, useContext, useEffect, useId, useMemo, useState } from 'react';

type Menu = ComponentProps['Generic']['Menu'];

function Trigger({ children }:Menu['Trigger']) {
  return children;
}

const MenuSide = createContext<'outside-left' | 'outside-right' | 'outside-bottom'>('outside-bottom');
const ReturnFocusToEditor = createContext(false);
const AnchorLabel = createContext<string | undefined>(undefined);

export const CloseTouchMenu = createContext<(() => void) | undefined>(undefined);

export function TouchToolbarMenu({ anchor, children }:PropsWithChildren<{ anchor:ReactElement<React.HTMLAttributes<HTMLElement>> }>) {
  const [openedBy, setOpenedBy] = useState<'touch' | 'keyboard'>();
  const keepFocus = openedBy === 'touch';
  return (
    <AnchoredOverlay
      open={!!openedBy}
      onOpen={(gesture) => setOpenedBy(gesture === 'anchor-key-press' ? 'keyboard' : 'touch')}
      onClose={() => setOpenedBy(undefined)}
      renderAnchor={(props) => cloneElement<React.HTMLAttributes<HTMLElement>>(anchor, { ...props, onMouseDown: preventFocusOnTap })}
      side="outside-top"
      displayInViewport
      focusTrapSettings={{ disabled: !openedBy || keepFocus }}
      focusZoneSettings={{ disabled: !openedBy || keepFocus }}
      overlayProps={{
        className: 'op-blocknote-action-menu op-blocknote-touch-menu',
        preventFocusOnOpen: keepFocus, preventFocusOnClose: keepFocus, onMouseDown: preventFocusOnTap, overflow: 'auto',
      }}
    >
      <CloseTouchMenu.Provider value={() => setOpenedBy(undefined)}>{children}</CloseTouchMenu.Provider>
    </AnchoredOverlay>
  );
}

function Root({ children, onOpenChange, portalElement, position, sub, preventFocusOnOpen }:Menu['Root']) {
  const { portalContainerName } = useContext(PortalContext);
  const label = useContext(AnchorLabel);
  const side = position === 'left' ? 'outside-left' : position === 'right' ? 'outside-right' : 'outside-bottom';
  const changeOpen = (open:boolean) => {
    if (open && portalElement && portalContainerName) registerPortalRoot(portalElement, portalContainerName);
    onOpenChange?.(open);
  };
  const slots = Children.toArray(children).filter(isValidElement).map((child) => {
    if (child.type === Trigger && isValidElement<Menu['Trigger']>(child) && isValidElement(child.props.children)) {
      return <ActionMenu.Anchor {...(label && !sub ? { 'aria-label': label } : {})}>{child.props.children}</ActionMenu.Anchor>;
    }
    return child;
  });

  const returnFocusToEditor = useContext(ReturnFocusToEditor);
  if (preventFocusOnOpen) {
    const parts = Children.toArray(children);
    const trigger = parts.find(child => isValidElement(child) && child.type === Trigger);
    const dropdown = parts.find(child => isValidElement(child) && child.type === Dropdown);
    if (isValidElement<Menu['Trigger']>(trigger) && isValidElement<React.HTMLAttributes<HTMLElement> & { label?:string }>(trigger.props.children) && isValidElement<Menu['Dropdown']>(dropdown)) {
      return (
        <TouchToolbarMenu anchor={trigger.props.children}>
          <ActionList role="menu" aria-label={trigger.props.children.props.label} disableFocusZone>
            <MenuContents {...dropdown.props} />
          </ActionList>
        </TouchToolbarMenu>
      );
    }
  }
  return (
    <ReturnFocusToEditor.Provider value={returnFocusToEditor && !sub}>
      <MenuSide.Provider value={side}><ActionMenu onOpenChange={changeOpen}>{slots}</ActionMenu></MenuSide.Provider>
    </ReturnFocusToEditor.Provider>
  );
}

const InColorGroup = createContext(false);

function MenuContents({ children, className }:Menu['Dropdown']) {
  const dict = useDictionary();
  if (!className?.split(' ').includes('bn-color-picker-dropdown')
    || !isValidElement<{ text?:unknown; background?:unknown }>(children)) return children;

  return (
    <InColorGroup.Provider value>
      {(['text', 'background'] as const).filter(kind => children.props[kind]).map((kind, index) => (
        <Fragment key={kind}>
          {index > 0 && <ActionList.Divider />}
          <ActionList.Group selectionVariant="single">
            <ActionList.GroupHeading>{dict.color_picker[`${kind}_title`]}</ActionList.GroupHeading>
            {cloneElement(children, kind === 'text' ? { background: undefined } : { text: undefined })}
          </ActionList.Group>
        </Fragment>
      ))}
    </InColorGroup.Provider>
  );
}

function Dropdown({ children, className }:Menu['Dropdown']) {
  const side = useContext(MenuSide);
  const editor = useBlockNoteEditor();
  const returnFocusToEditor = useContext(ReturnFocusToEditor);
  const editorRef = useMemo(() => ({ current: editor.domElement ?? null }), [editor]);
  return (
    <ActionMenu.Overlay
      className="op-blocknote-action-menu"
      side={side}
      overflow="auto"
      maxHeight="large"
      {...(returnFocusToEditor && { returnFocusRef: editorRef })}
    >
      <ActionList className={className}><MenuContents className={className}>{children}</MenuContents></ActionList>
    </ActionMenu.Overlay>
  );
}

function Item({ children, icon, checked, onClick, subTrigger, ...rest }:Menu['Item']) {
  const inColorGroup = useContext(InColorGroup);
  const close = useContext(CloseTouchMenu);
  const item = (
    <ActionList.Item
      {...rest}
      role={inColorGroup ? 'menuitemradio' : undefined}
      selected={checked}
      aria-keyshortcuts={inColorGroup && typeof children === 'string' ? children[0]?.toLowerCase() : undefined}
      onSelect={subTrigger ? undefined : () => { onClick?.(); close?.(); }}
    >
      {icon && <ActionList.LeadingVisual aria-hidden>{icon}</ActionList.LeadingVisual>}
      {children}
    </ActionList.Item>
  );
  return checked !== undefined && !inColorGroup
    ? <ActionList.Group selectionVariant="multiple" className="op-blocknote-toggle-group">{item}</ActionList.Group>
    : item;
}

function Label({ children }:Menu['Label']) {
  if (useContext(InColorGroup)) return null;
  return <ActionList.GroupHeading headingWrapElement="li">{children}</ActionList.GroupHeading>;
}

const HandleButton = forwardRef<HTMLButtonElement, Menu['Button']>(
  function HandleButton({ label, children, icon, ...button }, ref) {
    const anchorLabel = useContext(AnchorLabel);
    const name = label ?? anchorLabel;
    if (!name) return <button type="button" ref={ref} {...button}>{icon ?? children}</button>;

    return <IconButton {...button} ref={ref} aria-label={name} icon={icon ?? children} variant="invisible" size="small" />;
  },
);

const SideMenuButton = forwardRef<HTMLButtonElement, Menu['Button']>(
  function SideMenuButton({ icon, ...button }, ref) {
    if (button.draggable) return <HandleButton ref={ref} {...button} icon={<GrabberIcon data-test="dragHandle" />} />;
    // BlockNote 0.55 puts the add-block action on its icon (SE-661).
    if (isValidElement<{ onClick?:() => void }>(icon) && icon.props.onClick && !button.onClick) {
      return <HandleButton ref={ref} {...button} icon={<PlusIcon data-test="dragHandleAdd" />} onClick={icon.props.onClick} />;
    }
    return <HandleButton ref={ref} {...button} icon={icon} />;
  },
);

export function PrimerMenuPortal({ children }:PropsWithChildren) {
  const portalContainerName = useId();
  const value = useMemo(() => ({ portalContainerName }), [portalContainerName]);
  useEffect(() => () => registerPortalRoot(document.body, portalContainerName), [portalContainerName]);

  return <PortalContext.Provider value={value}>{children}</PortalContext.Provider>;
}

export const primerSideMenu = {
  Root: (props:ComponentProps['SideMenu']['Root']) => <div {...props} />,
  Button: SideMenuButton,
};
export const primerTableHandle = { Root: HandleButton, ExtendButton: HandleButton };
export const primerMenu = { Root, Trigger, Dropdown, Divider: ActionList.Divider, Item, Label, Button: HandleButton };

export function PrimerActionMenus({ children, label, returnFocusToEditor = false }:PropsWithChildren<{ label?:string, returnFocusToEditor?:boolean }>) {
  return (
    <ReturnFocusToEditor.Provider value={returnFocusToEditor}>
      <AnchorLabel.Provider value={label}>
        {children}
      </AnchorLabel.Provider>
    </ReturnFocusToEditor.Provider>
  );
}
