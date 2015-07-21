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

module.exports = function(
  workPackageAttachmentsService,
  I18n,
  ConfigurationService,
  ConversionService
) {
  var editMode = function(attrs) {
    return typeof attrs.edit !== 'undefined';
  }

  var attachmentsController = function(scope, element, attrs, fieldCtrl) {

    var workPackage = scope.workPackage(),
        upload = function(event, workPackage) {
          event.stopPropagation();
          workPackageAttachmentsService.upload(workPackage, scope.files).then(function() {
            scope.files = [];
          }).finally(loadAttachments);
        },
        loadAttachments = function() {
          if (!editMode(attrs)) {
            return;
          }
          scope.loading = true;
          workPackageAttachmentsService.load(workPackage).then(function(attachments) {
            scope.attachments = attachments;
          }).finally(function() {
            scope.loading = false;
          });
        }

    scope.instantUpload = function() {
      scope.$emit('uploadPendingAttachments', workPackage);
    }

    scope.remove = function(file) {
      workPackageAttachmentsService.remove(file).then(function(file) {
        _.remove(scope.attachments, file);
        _.remove(scope.files, file);
      });
    };

    scope.$on('uploadPendingAttachments', upload);
    scope.I18n = I18n;
    scope.megabytes = ConversionService.megabytes;

    scope.fetchingConfiguration = true;
    ConfigurationService.api().then(function(settings) {
      scope.maximumFileSize = settings.maximumAttachmentFileSize;
      // somehow, I18n cannot interpolate function results, so we need to cache this once
      scope.maxFileSizeMB = scope.megabytes(settings.maximumAttachmentFileSize);
      scope.fetchingConfiguration = false;
    });

    loadAttachments();
  };

  return {
    restrict: 'E',
    replace: true,
    reqire: '^workPackageField',
    scope: {
      workPackage: '&'
    },
    templateUrl: function(element, attrs) {
      if (editMode(attrs)) {
        return '/templates/work_packages/attachments-edit.html';
      }
      return '/templates/work_packages/attachments.html';
    },
    link: attachmentsController
  };
};
