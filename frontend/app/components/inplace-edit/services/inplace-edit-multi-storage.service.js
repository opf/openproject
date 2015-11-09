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
  .module('openproject.inplace-edit')
  .factory('inplaceEditMultiStorage', inplaceEditMultiStorage);


function inplaceEditMultiStorage($rootScope, $q, inplaceEditStorage, EditableFieldsState,
    NotificationsService) {

  $rootScope.$on('inplaceEditMultiStorage.save.workPackage', function (event, promise) {
    promise.catch(function (errors) {
      var errorMessages = _.flatten(_.map(errors), true);
      NotificationsService.addError(I18n.t('js.label_validation_error'), errorMessages);
    });
  });

  $rootScope.$on('inplaceEditMultiStorage.save.comment', function (event, promise) {
    promise.then(function() {
      NotificationsService.addSuccess(I18n.t('js.work_packages.comment_added'));
    }).catch(function() {
      NotificationsService.addError(I18n.t('js.work_packages.comment_send_failed'));
    });
  });

  return {
    save: function () {
      var promises = [];

      angular.forEach(_.sortBy(this.stores, 'index'), function (store) {
        if (store.active) {
          promises[store.index] = store.run().then(function () {
            store.active = false;
          });

          $rootScope.$broadcast(
            'inplaceEditMultiStorage.save.' + store.name, promises[store.index]);
        }
      });

      return $q.all(promises).then(function () {
        EditableFieldsState.currentField = null;

        $rootScope.$broadcast('workPackageRefreshRequired');

      }).finally(function () {
        promises = [];
        EditableFieldsState.errors = null;
        EditableFieldsState.isBusy = false;
      });
    },

    stores: {
      workPackage: {
        name: 'workPackage',
        active: false,
        index: 0,
        run: function () {
          return inplaceEditStorage.saveWorkPackage();
        }
      },

      comment: {
        name: 'comment',
        active: false,
        index: 1,
        run: function () {
          return inplaceEditStorage.addComment(this.value);
        },
        value: null
      }
    }
  };
}
