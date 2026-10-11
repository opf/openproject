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

import { ComponentProps, ComponentsContext, useBlockNoteEditor, useComponentsContext, useUIMode } from '@blocknote/react';
import { ActionList, ActionMenu, PortalContext, registerPortalRoot } from '@primer/react';
import { CheckIcon } from '@primer/octicons-react';
import { Children, createContext, isValidElement, PropsWithChildren, ReactElement, useContext, useEffect, useId, useMemo } from 'react';

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
    if (isValidElement<{ children:ReactElement }>(child) && child.type === Trigger) {
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
      <ActionList className={className}>{children}</ActionList>
    </ActionMenu.Overlay>
  );
}

function Item({ children, icon, checked, onClick, subTrigger, ...rest }:Menu['Item']) {
  return (
    <ActionList.Item
      {...rest}
      role={checked === undefined ? 'menuitem' : 'menuitemcheckbox'}
      aria-checked={checked}
      onSelect={subTrigger ? undefined : onClick}
    >
      {icon && <ActionList.LeadingVisual>{icon}</ActionList.LeadingVisual>}
      {children}
      {checked && <ActionList.TrailingVisual><CheckIcon /></ActionList.TrailingVisual>}
    </ActionList.Item>
  );
}

function Label({ children }:Menu['Label']) {
  return <ActionList.GroupHeading headingWrapElement="li">{children}</ActionList.GroupHeading>;
}

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
    Generic: {
      ...components.Generic,
      Menu: { ...components.Generic.Menu, Root, Trigger, Dropdown, Item, Label },
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
