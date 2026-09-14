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

export function registerInputCaptionStreamAction() {
  StreamActions.addInputCaption = function addInputCaptionAction(this:StreamElement) {
    const target = document.querySelector(this.target);
    if (target) {
      const formControl = (target as HTMLElement).closest('.FormControl')!;

      if (this.getAttribute('clean_other_captions') === 'true') {
        formControl
          .querySelectorAll('.FormControl-caption')
          .forEach((caption) => caption.remove());
      }

      const caption = this.getAttribute('caption');
      if (caption && caption !== '') {
        const span = document.createElement('span');
        span.className = 'FormControl-caption';
        span.innerText = caption;
        formControl.append(span);
      }
    }
  };
}
