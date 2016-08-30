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

function ShareModalController($scope,
                              shareModal,
                              QueryService,
                              AuthorisationService,
                              NotificationsService) {
  this.name = 'Share';
  this.closeMe = shareModal.deactivate;
  $scope.query = QueryService.getQuery();

  $scope.shareSettings = {
    starred: $scope.query.starred
  };

  function closeAndReport(message) {
    shareModal.deactivate();
    NotificationsService.addSuccess(message.text);
  }

  $scope.cannot = AuthorisationService.cannot;

  $scope.saveQuery = () => {
    var messageObject;

    QueryService.saveQuery()
      .then(data => {
        messageObject = data.status;
        if (data.query) {
          AuthorisationService.initModelAuth('query', data.query._links);
        }

        if ($scope.query.starred !== $scope.shareSettings.starred) {
          QueryService.toggleQueryStarred($scope.query)
            .then(data => {
              closeAndReport(data.status || messageObject);
              return $scope.query;
            });
        }
        else {
          closeAndReport(messageObject);
        }
      });
  };
}

function shareModalService(btfModal) {
  return btfModal({
    controller: ShareModalController,
    controllerAs: '$ctrl',
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

          <h3>{{ ::I18n.t('js.label_share') }}</h3>

          <div class="form--field -wide-label">
            <div class="form--field-container -vertical">
              <label class="form--label-with-check-box">
                <div class="form--check-box-container">
                  <input type="checkbox"
                     name="is_public"
                     id="show-public"
                     ng-model="query.isPublic"
                     ng-disabled="cannot('query', 'publicize') && cannot('query', 'depublicize')"
                     class="form--check-box"
                     focus />
                </div>
                {{ ::I18n.t('js.label_visible_for_others') }}
              </label>
              <label class="form--label-with-check-box">
                <div class="form--check-box-container">
                  <input type="checkbox"
                     name="show_in_menu"
                     id="show-in-menu"
                     ng-model="shareSettings.starred"
                     ng-disabled="query.isGlobal() || cannot('query', 'star')"
                     class="form--check-box" />
                </div>
                {{ ::I18n.t('js.label_show_in_menu') }}
              </label>
            </div>
          </div>

          <button class="button -highlight -with-icon icon-checkmark" ng-click="saveQuery()">
            {{ ::I18n.t('js.modals.button_save') }}
          </button>
          <button class="button" ng-click="$ctrl.closeMe()">
            {{ ::I18n.t('js.modals.button_cancel') }}
          </button>
        </div>
      </div>`
  });
}

wpControllersModule.factory('shareModal', shareModalService);
