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

import { ComponentProps, ComponentsContext, PortalElementOverride, preventFocusOnTap, useComponentsContext } from '@blocknote/react';
import { OpenProjectFormattingToolbar } from '@openproject/blocknote-extensions';
import { ActionList, ActionMenu, Button, IconButton, PortalContext, registerPortalRoot, Stack } from '@primer/react';
import { useContext, useId, useLayoutEffect, useMemo } from 'react';

type Toolbar = ComponentProps['FormattingToolbar'];

function ToolbarRoot({ className, children, onMouseEnter, onMouseLeave }:Toolbar['Root']) {
  return (
    <Stack
      role="toolbar"
      aria-label={window.I18n.t('js.blocknote.formatting_toolbar')}
      className={`${className} op-primer-formatting-toolbar`}
      direction="horizontal"
      align="center"
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
    >
      {children}
    </Stack>
  );
}

function ToolbarButton({
  children, icon, isSelected, isDisabled, label, mainTooltip, secondaryTooltip, variant, ...rest
}:Toolbar['Button']) {
  const props = {
    ...rest,
    variant: 'invisible' as const,
    size: 'small' as const,
    disabled: isDisabled,
    'aria-pressed': isSelected,
    'data-compact': variant === 'compact' || undefined,
    onMouseDown: preventFocusOnTap,
  };

  if (children) {
    return <Button {...props} aria-label={label} title={mainTooltip}>{children}</Button>;
  }

  return (
    <IconButton
      {...props}
      icon={icon}
      aria-label={mainTooltip ?? label ?? ''}
      keybindingHint={secondaryTooltip?.replace(/^(⌘|Ctrl)\+/, 'Mod+')}
    />
  );
}

function BlockTypeSelect({ items, isDisabled, portalElement }:Toolbar['Select']) {
  const { portalContainerName } = useContext(PortalContext);
  useLayoutEffect(() => {
    if (!portalElement || !portalContainerName) return undefined;
    registerPortalRoot(portalElement, portalContainerName);
    return () => registerPortalRoot(document.body, portalContainerName);
  }, [portalElement, portalContainerName]);

  const selectedItem = items.find((item) => item.isSelected);
  if (!selectedItem) return null;

  return (
    <ActionMenu>
      <ActionMenu.Button
        size="small"
        variant="invisible"
        disabled={isDisabled}
        onMouseDown={preventFocusOnTap}
        aria-label={`${window.I18n.t('js.blocknote.block_type')}: ${selectedItem.text}`}
      >
        {selectedItem.text}
      </ActionMenu.Button>
      <ActionMenu.Overlay className="op-blocknote-action-menu" maxHeight="medium" overflow="auto">
        <ActionList selectionVariant="single">
          {items.map((item) => (
            <ActionList.Item key={item.text} selected={item.isSelected} disabled={item.isDisabled} onSelect={item.onClick}>
              <ActionList.LeadingVisual>{item.icon}</ActionList.LeadingVisual>
              {item.text}
            </ActionList.Item>
          ))}
        </ActionList>
      </ActionMenu.Overlay>
    </ActionMenu>
  );
}

export function PrimerFormattingToolbar() {
  const components = useComponentsContext()!;
  const portalContainerName = useId();
  const portalContext = useMemo(() => ({ portalContainerName }), [portalContainerName]);
  const value = useMemo(() => ({
    ...components,
    FormattingToolbar: {
      Root: ToolbarRoot,
      Button: ToolbarButton,
      Select: (props:Toolbar['Select']) => props.preventFocusOnOpen
        ? <components.FormattingToolbar.Select {...props} />
        : <BlockTypeSelect {...props} />,
    },
  }), [components]);

  return (
    <PortalElementOverride target={document.body}>
      <PortalContext.Provider value={portalContext}>
        <ComponentsContext.Provider value={value}><OpenProjectFormattingToolbar /></ComponentsContext.Provider>
      </PortalContext.Provider>
    </PortalElementOverride>
  );
}
