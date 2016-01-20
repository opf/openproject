// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

angular
  .module('openproject.workPackages.controllers')
  .controller('AttachmentsSimpleModalController',
    AttachmentsSimpleModalController);

function AttachmentsSimpleModalController($scope,
                                          $rootScope,
                                          attachmentsSimpleModal) {

  var vm = this;
  var data = attachmentsSimpleModal.data;
  var options = attachmentsSimpleModal.options;
  var modal = attachmentsSimpleModal.modal;

  console.log("modaloptions:");
  console.log(attachmentsSimpleModal.options);
  vm.data = data;
  vm.options = options;

  // always suggest to insert images as inline-image
  vm.userInput = {
    insertMode: "inline"
  };

  vm.text = {
    /* TODO: I18 Support */
    modalTitle: vm.options.modalTitle,

    //input fields
    insertAs: "Insert as",

    // insert as
    insertAsInlineImage: "Inline-Image",
    insertAsAlternative: (vm.options.insertAsAlternative == "attachment") ? "Attachment" : "Web-Link",

    // Buttons
    closePopup: I18n.t('js.close_popup_title'),
    applyButton: I18n.t('js.modals.button_apply'),
    cancelButton: I18n.t('js.modals.button_cancel')
  };

  vm.ok = function(){
    attachmentsSimpleModal.data = {
      insertMode: vm.userInput.insertMode
    };

   vm.closeMe();
  };

  vm.closeMe = function(){
    $rootScope.$broadcast("AttachmentsSimpleModalClosed");
    modal.deactivate();
  };

}
