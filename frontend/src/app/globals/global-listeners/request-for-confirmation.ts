//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { OpModalService } from "core-app/modules/modal/modal.service";
import { PasswordConfirmationModal } from "core-components/modals/request-for-confirmation/password-confirmation.modal";

function registerListener(
  form:JQuery,
  $event:JQuery.TriggeredEvent,
  opModalService:OpModalService,
  modal:typeof PasswordConfirmationModal) {
  const passwordConfirm = form.find('_password_confirmation');

  if (passwordConfirm.length > 0) {
    return true;
  }

  $event.preventDefault();
  const confirmModal = opModalService.show(modal, 'global');
  confirmModal.closingEvent.subscribe((modal:any) => {
    if (modal.confirmed) {
      jQuery('<input>')
        .attr({
          type: 'hidden',
          name: '_password_confirmation',
          value: modal.password_confirmation
        })
        .appendTo(form);

      form.trigger('submit');
    }
  });

  return false;
}

export function registerRequestForConfirmation($:JQueryStatic) {
  window.OpenProject
    .getPluginContext()
    .then((context) => {
      const opModalService = context.services.opModalService;
      const passwordConfirmationModal = context.classes.modals.passwordConfirmation;

      $(document).on(
        'submit',
        'form[data-request-for-confirmation]',
        function(this:any, $event:JQuery.TriggeredEvent) {
          const form = jQuery(this);

          if (form.find('input[name="_password_confirmation"]').length) {
            return true;
          }

          return registerListener(form, $event, opModalService, passwordConfirmationModal);
        });
    });
}
