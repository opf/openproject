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

import { LinkToolbarExtension } from '@blocknote/core/extensions';
import {
  type ComponentProps, DeleteLinkButton, EditLinkButton, GenericPopover, LinkToolbar, type LinkToolbarProps, OpenLinkButton, PortalElementOverride, preventFocusOnTap,
  useBlockNoteEditor, useEditorDOMElement, useExtension,
} from '@blocknote/react';
import { flip, offset, safePolygon } from '@floating-ui/react';
import { LinkExternalIcon, UnlinkIcon } from '@primer/octicons-react';
import { Button, IconButton, Stack } from '@primer/react';
import {
  createContext, type ReactElement, useContext, useEffect, useState,
} from 'react';

import { PrimerToolbarForm } from './PrimerToolbarForm';
import { PrimerMenuPortal } from './PrimerActionMenus';

function LinkToolbarRoot({ children }:ComponentProps['LinkToolbar']['Root']) {
  return <Stack className="op-blocknote-link-toolbar" direction="horizontal" gap="none">{children}</Stack>;
}

const LinkIcon = createContext<ReactElement | null>(null);

function LinkButton({ children, label, mainTooltip, icon, isSelected: _isSelected, isDisabled, ...props }:ComponentProps['LinkToolbar']['Button']) {
  const overrideIcon = useContext(LinkIcon);
  return children
    ? <Button {...props} variant="invisible" size="medium" disabled={isDisabled} onMouseDown={preventFocusOnTap}>{children}</Button>
    : <IconButton {...props} icon={overrideIcon ?? icon} aria-label={label ?? mainTooltip ?? ''} size="medium"
        variant="invisible" disabled={isDisabled} onMouseDown={preventFocusOnTap} />;
}

export const primerLinkToolbar = { Root: LinkToolbarRoot, Button: LinkButton };

type ActiveLink = Pick<LinkToolbarProps, 'url' | 'text' | 'range'> & {
  reference:{ element:HTMLAnchorElement };
  source:'selection' | 'hover';
};

function FloatingLinkToolbar() {
  const editor = useBlockNoteEditor();
  const element = useEditorDOMElement();
  const links = useExtension(LinkToolbarExtension);
  const [active, setActive] = useState<ActiveLink>();
  const [open, setOpen] = useState(false);
  const [frozen, setFrozen] = useState(false);

  useEffect(() => {
    if (!element) return undefined;
    if (frozen && active) {
      const { element: anchor } = active.reference;
      return editor.onChange(() => {
        const link = element.contains(anchor) && links.getLinkAtElement(anchor);
        if (link) {
          setActive({ ...active, range: link.range, text: link.text, url: link.mark.attrs.href });
        } else {
          setFrozen(false);
          setActive(undefined);
          setOpen(false);
        }
      });
    }
    let timer:number | undefined;

    function activate(link:NonNullable<ReturnType<typeof links.getLinkAtSelection>>, source:ActiveLink['source']) {
      const anchor = links.getLinkElementAtPos(link.range.from);
      if (!anchor) return;
      setActive({ url: link.mark.attrs.href, text: link.text, range: link.range, reference: { element: anchor }, source });
      setOpen(true);
    }

    function selectionChanged() {
      window.clearTimeout(timer);
      const link = links.getLinkAtSelection();
      if (link) activate(link, 'selection');
      else {
        setActive(undefined);
        setOpen(false);
      }
    }

    function hover(event:MouseEvent) {
      const anchor = event.target instanceof Element && event.target.closest('a');
      if (!anchor || anchor.contains(event.relatedTarget instanceof Node ? event.relatedTarget : null)) return;
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        if (!anchor.matches(':hover') || !element?.contains(anchor) || links.getLinkAtSelection()) return;
        const link = links.getLinkAtElement(anchor);
        if (link) activate(link, 'hover');
      }, 250);
    }

    const offChange = editor.onChange(selectionChanged);
    const offSelection = editor.onSelectionChange(selectionChanged);
    element.addEventListener('mouseover', hover);
    return () => {
      window.clearTimeout(timer);
      element.removeEventListener('mouseover', hover);
      offSelection();
      offChange();
    };
  }, [active, editor, element, frozen, links]);

  if (!active || !editor.isEditable) return null;
  const controls = { url: active.url, text: active.text, range: active.range, setToolbarOpen: setOpen, setToolbarPositionFrozen: setFrozen };
  return (
    <GenericPopover reference={active.reference}
      useFloatingOptions={{
        open, placement: 'top-start', middleware: [offset(10), flip()],
        onOpenChange(next, _event, reason) {
          if (frozen || (reason === 'hover' && active.source === 'selection')) return;
          if (reason === 'escape-key') editor.focus();
          setOpen(next);
        },
      }}
      useHoverProps={{ enabled: active.source === 'hover', delay: { open: 250, close: 250 }, handleClose: safePolygon() }}
      focusManagerProps={{ disabled: true }} elementProps={{ style: { zIndex: 50 } }}>
      <LinkToolbar {...controls}>
        <EditLinkButton {...controls} />
        <LinkIcon.Provider value={<LinkExternalIcon />}><OpenLinkButton url={active.url} /></LinkIcon.Provider>
        <LinkIcon.Provider value={<UnlinkIcon />}><DeleteLinkButton range={active.range} setToolbarOpen={setOpen} /></LinkIcon.Provider>
      </LinkToolbar>
    </GenericPopover>
  );
}

export function PrimerLinkToolbar() {
  return (
    <PrimerMenuPortal>
      <PrimerToolbarForm>
        <PortalElementOverride target={document.body}>
          <FloatingLinkToolbar />
        </PortalElementOverride>
      </PrimerToolbarForm>
    </PrimerMenuPortal>
  );
}
