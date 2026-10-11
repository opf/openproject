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

import { ComponentProps, ComponentsContext, SideMenu, SideMenuController, useComponentsContext, usePortalElement } from '@blocknote/react';
import { ActionList, ActionMenu, PortalContext, registerPortalRoot } from '@primer/react';
import { CheckIcon } from '@primer/octicons-react';
import { Children, isValidElement, ReactElement, useContext, useId, useLayoutEffect, useMemo } from 'react';

type Menu = ComponentProps['Generic']['Menu'];

function Trigger({ children }:Menu['Trigger']) {
  return children;
}

function Root({ children, onOpenChange }:Menu['Root']) {
  const slots = Children.toArray(children).filter(isValidElement).map((child) => {
    if (isValidElement<{ children:ReactElement }>(child) && child.type === Trigger) {
      return <ActionMenu.Anchor>{child.props.children}</ActionMenu.Anchor>;
    }
    return child;
  });

  return <ActionMenu onOpenChange={onOpenChange}>{slots}</ActionMenu>;
}

function Dropdown({ children, className, sub }:Menu['Dropdown']) {
  return (
    <ActionMenu.Overlay className="op-blocknote-action-menu" side={sub ? 'outside-right' : 'outside-left'} overflow="auto" maxHeight="large">
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

function PrimerSideMenu() {
  const components = useComponentsContext()!;
  const portalElement = usePortalElement();
  const { portalContainerName } = useContext(PortalContext);
  useLayoutEffect(() => {
    if (!portalElement || !portalContainerName) return undefined;
    registerPortalRoot(portalElement, portalContainerName);
    return () => registerPortalRoot(document.body, portalContainerName);
  }, [portalElement, portalContainerName]);

  const value = useMemo(() => ({
    ...components,
    Generic: {
      ...components.Generic,
      Menu: { ...components.Generic.Menu, Root, Trigger, Dropdown, Item, Label },
    },
  }), [components]);

  return <ComponentsContext.Provider value={value}><SideMenu /></ComponentsContext.Provider>;
}

export function PrimerSideMenuController() {
  const portalContainerName = useId();
  const portalContext = useMemo(() => ({ portalContainerName }), [portalContainerName]);
  return (
    <PortalContext.Provider value={portalContext}>
      <SideMenuController sideMenu={PrimerSideMenu} portalElement={document.body} />
    </PortalContext.Provider>
  );
}
