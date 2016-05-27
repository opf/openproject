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

function foundationModal($timeout, ModalFactory) {
  var foundationModalController = function(scope, element) {
    var modal = new ModalFactory({
      template: element.find('.foundation-modal--template').html(),
      id: scope.modalId,
      // Set if the modal has a background overlay
      overlay: true,
      // Set if the modal can be closed by clicking on the overlay
      overlayClose: false,
      // Allows you to pass in properties to the scope of the modal
      contentScope: {
        close: function() {
          modal.deactivate();
        }
      }
    });

    if(scope.modalStartOnShow) {
      modal.activate();
    } else {
      element.find('.foundation-modal--activate-link').click(function() {
        modal.activate();
      });
    }
  };

  return {
    restrict: 'E',
    scope: {
      modalId: '@',
      modalStartOnShow: '='
    },
    link: foundationModalController
  };
}

angular
  .module('openproject.uiComponents')
  .directive('foundationModal', foundationModal);
