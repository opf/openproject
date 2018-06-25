//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

/**
 * Listen to failed avatar load requests and replace them with the default icon
 */
export function registerGlobalAvatarFallback($:JQueryStatic) {
  $(function() {
    // We can employ useCapture to avoid binding to every image#error event
    window.addEventListener('error', (evt) => {
      const target = evt.target as HTMLElement;

      // Replace if we hit a gravatar image
      if (!(target.tagName === 'IMG' && target.classList.contains('avatar--gravatar-image'))) {
        return;
      }

      // We need to replace all gravatars with the same source since the error event
      // is fired only once
      const src = (target as HTMLImageElement).src;
      $(`img.avatar--gravatar-image[src="${src}"]`).each((i, el) => {
        const target = $(el);
        const classes = target.data('avatarFallbackIcon');

        target.replaceWith(
          $('<i>')
            .addClass(classes)
            .prop('aria-hidden', true)
        );
      });
    }, true);
  });
}
