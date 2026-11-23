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
import { type ComponentProps, useAutoFocus, useBlockNoteEditor } from '@blocknote/react';
import { AnchoredOverlay, Button, FormControl, PortalContext, registerPortalRoot, TextInput } from '@primer/react';
import { cloneElement, createContext, isValidElement, useContext, useId, useLayoutEffect, useMemo, useRef, useState } from 'react';
import type { ComponentPropsWithRef, PropsWithChildren, RefObject } from 'react';

type Popover = ComponentProps['Generic']['Popover'];
type Form = ComponentProps['Generic']['Form'];

const LiveForm = createContext(false);

const FormPopoverContext = createContext<{
  open:boolean;
  setOpen:(open:boolean) => void;
  anchorRef:RefObject<HTMLButtonElement | null>;
  labelId:string;
  portalContainerName?:string;
} | null>(null);

function FormPopover({ open: controlledOpen, onOpenChange, portalElement, children }:Popover['Root']) {
  const [localOpen, setLocalOpen] = useState(false);
  const labelId = useId();
  const anchorRef = useRef<HTMLButtonElement>(null);
  const { portalContainerName } = useContext(PortalContext);
  useLayoutEffect(() => {
    if (!portalElement || !portalContainerName) return undefined;
    registerPortalRoot(portalElement, portalContainerName);
    return () => registerPortalRoot(document.body, portalContainerName);
  }, [portalElement, portalContainerName]);
  const value = useMemo(() => ({
    open: controlledOpen ?? localOpen, anchorRef, labelId, portalContainerName,
    setOpen(open:boolean) {
      setLocalOpen(open);
      onOpenChange?.(open);
    },
  }), [controlledOpen, localOpen, onOpenChange, portalContainerName, labelId]);
  return <FormPopoverContext.Provider value={value}>{children}</FormPopoverContext.Provider>;
}

function FormTrigger({ children }:Popover['Trigger']) {
  const popup = useContext(FormPopoverContext);
  if (!popup || !isValidElement<ComponentPropsWithRef<'button'> & { label?:string, mainTooltip?:string }>(children)) return null;
  const label = children.props.label ?? children.props.children ?? children.props.mainTooltip;
  return (
    <>
      <span hidden id={popup.labelId}>{label}</span>
      {cloneElement(children, {
        ref: popup.anchorRef,
        'aria-haspopup': 'dialog',
        'aria-expanded': popup.open,
        onClick: children.props.onClick ?? (() => popup.setOpen(!popup.open)),
      })}
    </>
  );
}

function FormContent({ children }:Popover['Content']) {
  const popup = useContext(FormPopoverContext);
  const editor = useBlockNoteEditor();
  if (!popup) return null;
  return (
    <AnchoredOverlay renderAnchor={null} anchorRef={popup.anchorRef} open={popup.open} width="medium"
      focusZoneSettings={{ disabled: true }}
      onClose={(gesture) => {
        popup.setOpen(false);
        if (gesture === 'escape') editor.focus();
      }}
      overlayProps={{ preventFocusOnOpen: true, preventFocusOnClose: true, role: 'dialog', 'aria-labelledby': popup.labelId, portalContainerName: popup.portalContainerName }}>
      {children}
    </AnchoredOverlay>
  );
}

function ToolbarForm({ children, onSubmit }:Form['Root']) {
  const t = useEditorTranslation();
  const live = useContext(LiveForm);
  return (
    <form className="op-blocknote-toolbar-form" onSubmit={(event) => {
      event.preventDefault();
      onSubmit?.();
    }}>
      {children}
      <Button type="submit" variant="primary">{t(live ? 'js.button_close' : 'js.button_save')}</Button>
    </form>
  );
}

function FormInput({ name, value, onChange, autoFocus, placeholder }:Form['TextInput']) {
  const t = useEditorTranslation();
  const live = useContext(LiveForm);
  const ref = useAutoFocus<HTMLInputElement>(autoFocus);
  useLayoutEffect(() => {
    // Primer TextInput exposes required via ARIA. Set the native constraint for form submission (SE-661).
    if (ref.current) ref.current.required = name === 'url';
  }, [name, ref]);
  return (
    <FormControl required={name === 'url'}>
      <FormControl.Label>{live ? placeholder : t(name === 'url' ? 'js.blocknote.link_url' : 'js.blocknote.link_text')}</FormControl.Label>
      <TextInput block name={name} value={value} onChange={onChange} ref={ref}
        placeholder={placeholder} pattern={name === 'url' ? '.*\\S.*' : undefined} autoComplete="off" />
    </FormControl>
  );
}

export const primerForm = { Root: ToolbarForm, TextInput: FormInput };
export const primerPopover = { Root: FormPopover, Trigger: FormTrigger, Content: FormContent };

export function PrimerToolbarForm({ children, live = false }:PropsWithChildren<{ live?:boolean }>) {
  return <LiveForm.Provider value={live}>{children}</LiveForm.Provider>;
}
