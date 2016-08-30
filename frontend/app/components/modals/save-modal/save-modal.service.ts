//-- copyright
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
//++

import {wpControllersModule} from '../../../angular-modules';

function SaveModalController($scope,
                             saveModal,
                             QueryService,
                             AuthorisationService,
                             $state,
                             NotificationsService) {
  this.name = 'Save';
  this.closeMe = saveModal.deactivate;

  $scope.saveQueryAs = name => {
    QueryService.saveQueryAs(name)
      .then(data => {

        if (data.status.isError) {
          NotificationsService.addError(data.status.text);
        }
        else {
          // push query id to URL without reinitializing work-packages-list-controller
          if (data.query) {
            $state.go('work-packages.list',
              {query_id: data.query.id, query: null},
              {notify: false});
            AuthorisationService.initModelAuth('query', data.query._links);
          }

          saveModal.deactivate();

          NotificationsService.addSuccess(data.status.text);
        }
      });
  };
}

function saveModalService(btfModal) {
  return btfModal({
    controller: SaveModalController,
    controllerAs: 'modal',
    afterFocusOn: '#work-packages-settings-button',
    template: `
      <div class="ng-modal-window">
        <div class="ng-modal-inner">
          <div class="modal-header">
            <a>
              <i
                class="icon-close"
                ng-click="$ctrl.closeMe()"
                title="{{ ::I18n.t('js.close_popup_title') }}">
              </i>
            </a>
          </div>

          <h3>{{ ::I18n.t('js.label_save_as') }}</h3>

          <form name="modalSaveForm" class="form">
            <div class="form--field -required">
              <label class="form--label">
                {{ ::I18n.t('js.modals.label_name') }}
              </label>
              <div class="form--field-container">
                <div class="form--text-field-container">
                  <input
                    class="form--text-field"
                    type="text"
                    name="save_query_name"
                    id="save-query-name"
                    ng-model="queryName" focus required />
                </div>
              </div>
            </div>
            <div class="form--space">
              <button class="button -highlight -with-icon icon-checkmark"
                ng-click="saveQueryAs(queryName)"
                ng-disabled="modalSaveForm.$invalid">
                {{ ::I18n.t('js.modals.button_save') }}
              </button>
              <button class="button" ng-click="$ctrl.closeMe()">
                {{ ::I18n.t('js.modals.button_cancel') }}
              </button>
            </div>
          </form>

        </div>
      </div>`
  });
}

wpControllersModule.factory('saveModal', saveModalService);
