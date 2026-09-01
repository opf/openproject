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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { StreamActions, StreamElement } from '@hotwired/turbo';
import { Idiomorph } from 'idiomorph';

export interface DialogCloseDetail<TAdditional = unknown> {
  dialog:HTMLDialogElement;
  submitted:boolean;
  additional?:TAdditional;
}

declare global {
  interface GlobalEventHandlersEventMap {
    'dialog:close':CustomEvent<DialogCloseDetail>;
  }
}

export function registerDialogStreamAction() {
  StreamActions.closeDialog = function closeDialogStreamAction(this:StreamElement) {
    const [dialog] = this.targetElements;

    if (!(dialog instanceof HTMLDialogElement)) {
      return;
    }

    const additionalData = JSON.parse(this.getAttribute('additional') ?? '{}') as unknown;

    // dispatching with submitted: true to indicate that the behavior of a successful submission should
    // be triggered (i.e. reloading the ui)
    document.dispatchEvent(new CustomEvent<DialogCloseDetail>('dialog:close', { detail: { dialog, submitted: true, additional: additionalData } }));
    dialog.close('close-event-already-dispatched');
  };

  StreamActions.dialog = function dialogStreamAction(this:StreamElement) {
    const content = this.templateElement.content;
    const dialog = content.querySelector('dialog')!;
    const existingElement = document.getElementById(dialog.id);
    let dialogToShow = dialog;

    if (existingElement instanceof HTMLDialogElement) {
      // a dialog with this id already exists: update (morph) its contents.
      Idiomorph.morph(existingElement, dialog.innerHTML, { morphStyle: 'innerHTML' });
      dialogToShow = existingElement;
    } else {
      // no dialog with this id exists: append <dialog-helper> to the body.
      document.body.append(content);

      // Remove the dialog on close
      dialog.addEventListener('close', () => {
        if (dialog.parentElement?.tagName === 'DIALOG-HELPER') {
          dialog.parentElement.remove();
        } else {
          dialog.remove();
        }

        if (dialog.returnValue !== 'close-event-already-dispatched') {
          document.dispatchEvent(new CustomEvent<DialogCloseDetail>('dialog:close', { detail: { dialog, submitted: false } }));
        }
      });
    }

    // Auto-show the modal
    dialogToShow.showModal();

    // Hack to fix the width calculation of nested elements
    // such as the CKEditor toolbar.
    setTimeout(() => {
      const width = dialogToShow.offsetWidth;
      dialogToShow.style.width = `${width + 1}px`;
    }, 250);
  };
}
