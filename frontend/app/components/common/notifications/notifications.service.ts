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

import {opServicesModule} from '../../../angular-modules';

function NotificationsService($rootScope:ng.IRootScopeService, $timeout:ng.ITimeoutService, ConfigurationService:any) {
  var createNotification = function (message:any) {
      if (typeof message === 'string') {
        return {message: message};
      }
      return message;
    },
    createSuccessNotification = function (message:any) {
      return _.extend(createNotification(message), {type: 'success'});
    },
    createWarningNotification = function (message:any) {
      return _.extend(createNotification(message), {type: 'warning'});
    },
    createErrorNotification = function (message:any, errors : Array<any>) {
      return _.extend(createNotification(message), {
        type: 'error',
        errors: errors
      });
    },
    createNoticeNotification = function (message:any) {
      return _.extend(createNotification(message), {type: 'info'});
    },
    createWorkPackageUploadNotification = function (message:any, uploads:Array<any>) {
      if (!uploads.length) {
        throw new Error('Cannot create an upload notification without uploads!');
      }
      return _.extend(createNotification(message), {
        type: 'upload',
        uploads: uploads
      });
    },
    broadcast = function (event:any, data:any) {
      $rootScope.$broadcast(event, data);
    },
    currentNotifications:any = [],
    notificationAdded = function (newNotification:any) {
      var toRemove = currentNotifications.slice(0);
      _.each(toRemove, function (existingNotification:any) {
        if (newNotification.type === 'success' || newNotification.type === 'error') {
          remove(existingNotification);
        }
      });

      currentNotifications.push(newNotification);
    },
    notificationRemoved = function (removedNotification:any) {
      _.remove(currentNotifications, function (element:any) {
        return element === removedNotification;
      });
    },
    clearNotifications = function () {
      currentNotifications.forEach(function (notification:any) {
        remove(notification);
      });
    };

  $rootScope.$on('notification.remove', function (_e, notification) {
    notificationRemoved(notification);
  });

  $rootScope.$on('notifications.clearAll', function () {
    clearNotifications();
  });

  // public
  var add = function (message:any, timeoutAfter = 5000) {
      var notification = createNotification(message);
      broadcast('notification.add', notification);
      notificationAdded(notification);
      if (message.type === 'success' && ConfigurationService.autoHidePopups()) {
        $timeout(() => remove(notification), timeoutAfter);
      }
      return notification;
    },
    addError = function (message:any, errors : Array<any> = []) {
      // depite the Typescript annotation,
      // errors might still be string
      if (!Array.isArray(errors)) {
        errors = [errors];
      }

      return add(createErrorNotification(message, errors));
    },
    addWarning = function (message:any) {
      return add(createWarningNotification(message));
    },
    addSuccess = function (message:any) {
      return add(createSuccessNotification(message));
    },
    addNotice = function (message:any) {
      return add(createNoticeNotification(message));
    },
    addWorkPackageUpload = function (message:any, uploads : Array<any>) {
      return add(createWorkPackageUploadNotification(message, uploads));
    },
    remove = function (notification:any) {
      broadcast('notification.remove', notification);
    },
    clear = function () {
      broadcast('notification.clearAll', null);
    };

  return {
    add: add,
    remove: remove,
    clear: clear,
    addError: addError,
    addWarning: addWarning,
    addSuccess: addSuccess,
    addNotice: addNotice,
    addWorkPackageUpload: addWorkPackageUpload
  };
}

opServicesModule.factory('NotificationsService', NotificationsService);
