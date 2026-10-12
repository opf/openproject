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

import { ComponentProps, ComponentsContext, useBlockNoteEditor, useComponentsContext, useDictionary, useUIMode } from '@blocknote/react';
import { ActionList, ActionMenu, IconButton, PortalContext, registerPortalRoot } from '@primer/react';
import { Children, cloneElement, createContext, forwardRef, Fragment, isValidElement, PropsWithChildren, useContext, useEffect, useId, useMemo } from 'react';

type Menu = ComponentProps['Generic']['Menu'];

function Trigger({ children }:Menu['Trigger']) {
  return children;
}

const MenuSide = createContext<'outside-left' | 'outside-right' | 'outside-bottom'>('outside-bottom');
const ReturnFocusToEditor = createContext(false);
const AnchorLabel = createContext<string | undefined>(undefined);

function Root({ children, onOpenChange, portalElement, position, sub }:Menu['Root']) {
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
  const item = (
    <ActionList.Item
      {...rest}
      selected={checked}
      aria-keyshortcuts={inColorGroup && typeof children === 'string' ? children[0]?.toLowerCase() : undefined}
      onSelect={subTrigger ? undefined : onClick}
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

    // BlockNote 0.55 puts the add-block action on its icon (SE-661).
    if (isValidElement<{ onClick?:() => void }>(icon) && icon.props.onClick && !button.onClick) {
      return <IconButton {...button} ref={ref} aria-label={name} icon={cloneElement(icon, { onClick: undefined })}
        onClick={icon.props.onClick} variant="invisible" size="small" />;
    }

    return <IconButton {...button} ref={ref} aria-label={name} icon={icon ?? children} variant="invisible" size="small" />;
  },
);

export function PrimerMenuPortal({ children }:PropsWithChildren) {
  const portalContainerName = useId();
  const value = useMemo(() => ({ portalContainerName }), [portalContainerName]);
  useEffect(() => () => registerPortalRoot(document.body, portalContainerName), [portalContainerName]);

  return <PortalContext.Provider value={value}>{children}</PortalContext.Provider>;
}

export function PrimerActionMenus({ children, label, returnFocusToEditor = false }:PropsWithChildren<{ label?:string, returnFocusToEditor?:boolean }>) {
  const components = useComponentsContext()!;
  const mode = useUIMode();
  const value = useMemo(() => ({
    ...components,
    SideMenu: { ...components.SideMenu, Button: HandleButton },
    TableHandle: { ...components.TableHandle, Root: HandleButton, ExtendButton: HandleButton },
    Generic: {
      ...components.Generic,
      Menu: { ...components.Generic.Menu, Root, Trigger, Dropdown, Item, Label, Button: HandleButton },
    },
  }), [components]);

  return (
    <ReturnFocusToEditor.Provider value={returnFocusToEditor}>
      <AnchorLabel.Provider value={label}>
        <ComponentsContext.Provider value={mode === 'mobile' ? components : value}>{children}</ComponentsContext.Provider>
      </AnchorLabel.Provider>
    </ReturnFocusToEditor.Provider>
  );
}
