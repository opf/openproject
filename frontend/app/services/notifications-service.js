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

module.exports = function(I18n, $rootScope) {
  'use strict';
  // private
  var createNotification = function(message) {
    if(typeof message === 'string') {
      return { message: message };
    }
    return message;
  },
  createSuccessNotification = function(message) {
    return _.extend(createNotification(message), { type: 'success' });
  },
  createWarningNotification = function(message) {
    return _.extend(createNotification(message), { type: 'warning' });
  },
  createErrorNotification = function(message, errors) {
    return _.extend(createNotification(message), {
      type: 'error',
      errors: errors || []
    });
  },
  createNoticeNotification = function(message) {
    return _.extend(createNotification(message), { type: '' });
  },
  createWorkPackageUploadNotification = function(message, uploads) {
    if(!uploads) {
      throw new Error('Cannot create an upload notification without uploads!');
    }
    return _.extend(createNotification(message), {
      type: 'upload',
      uploads: uploads
    });
  },
  broadcast = function(event, data) {
    $rootScope.$broadcast(event, data);
  };

  // public
  var add = function(message) {
    var notification = createNotification(message);
    broadcast('notification.add', notification);
    return notification;
  },
  addError = function(message, errors) {
    return add(createErrorNotification(message, errors));
  },
  addWarning = function(message) {
    return add(createWarningNotification(message));
  },
  addSuccess = function(message) {
    return add(createSuccessNotification(message));
  },
  addNotice = function(message) {
    return add(createNoticeNotification(message))
  },
  addWorkPackageUpload = function(message, uploads) {
    return add(createWorkPackageUploadNotification(message, uploads));
  },
  remove = function(notification) {
    broadcast('notification.remove', notification);
  };

  return {
    add: add,
    remove: remove,
    addError: addError,
    addWarning: addWarning,
    addSuccess: addSuccess,
    addNotice: addNotice,
    addWorkPackageUpload: addWorkPackageUpload
  };
};
