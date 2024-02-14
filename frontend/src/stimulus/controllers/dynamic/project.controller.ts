/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 *
 */

import { Controller } from '@hotwired/stimulus';
import { ModalDialogElement } from '@openproject/primer-view-components/app/components/primer/alpha/modal_dialog';

export default class ProjectController extends Controller {
  static targets = [
    'descriptionToggle',
    'projectRow',
    'descriptionRow',
  ];

  declare readonly descriptionToggleTargets:HTMLAnchorElement[];
  declare readonly projectRowTargets:HTMLTableRowElement[];
  declare readonly descriptionRowTargets:HTMLTableRowElement[];

  connect():void {
    const longTexts = document.querySelectorAll('.long-text-truncation');
    longTexts.forEach((e) => {
      const children = e.querySelectorAll('.op-uc-p');
      if (children.length) {
        const isEllipssed= this.isEllipsisActive(children[0] as HTMLElement);
        if (isEllipssed) {
          const a = document.createElement('a');
          a.href = '#';
          a.textContent = I18n.t('js.label_expand');
          a.addEventListener('click', () => {
            const modal = document.querySelector('#modalDesc') as ModalDialogElement;
            const modalBody = modal.querySelector('.Overlay-body');
            if (modalBody && a.previousElementSibling) {
              modalBody.textContent = a.previousElementSibling.textContent;
              modal.show();
            }
          });
          e.appendChild(a);
        }
      }
    });
  }

  isEllipsisActive(e:HTMLElement) {
    return (e.offsetWidth < e.scrollWidth);
  }
}
