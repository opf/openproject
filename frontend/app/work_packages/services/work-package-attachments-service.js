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

module.exports = function(Upload, PathHelper, I18n, NotificationsService, $q, $timeout, $http) {

  var upload = function(workPackage, files) {
    var uploadPath = workPackage.links.addAttachment.url();
    // for file in files build some promises, create a notification per WP,
    // notify the noticiation (wat?) about progress
    var uploads = _.map(files, function(file) {
      var options = {
        url: uploadPath,
        fields: {
          metadata: {
            fileName: file.name,
            description: file.description
          }
        },
        file: file
      };
      return Upload.upload(options);
    });

    // notify the user
    var message = I18n.t('js.label_upload_notification', {
      id: workPackage.props.id,
      subject: workPackage.props.subject
    });

    var notification = NotificationsService.addWorkPackageUpload(message, uploads);
    var allUploadsDone = $q.defer();
    $q.all(uploads).then(function() {
      $timeout(function() { // let the notification linger for a bit
        NotificationsService.remove(notification);
        allUploadsDone.resolve();
      }, 700);
    }, function(err) {
      allUploadsDone.reject();
    });
    return allUploadsDone.promise;
  },
  load = function(workPackage) {
    var path = workPackage.links.attachments.url(),
        attachments = $q.defer();
    $http.get(path).success(function(response) {
      attachments.resolve(response._embedded.elements)
    }).error(function(err) {
      attachments.reject(err);
    });
    return attachments.promise;
  },
  remove = function(fileOrAttachment) {
    var removal = $q.defer();
    if (angular.isObject(fileOrAttachment._links)) {
      var path = fileOrAttachment._links.self.href;
      $http.delete(path).success(function() {
        removal.resolve(fileOrAttachment);
      }).error(function(err) {
        removal.reject(err);
      });
    } else {
      removal.resolve(fileOrAttachment);
    }
    return removal.promise;
  }

  return {
    upload: upload,
    remove: remove,
    load: load
  };
};
