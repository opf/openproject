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

export class AvatarUploadFormController {
    // Form targets
    public form:any;
    public target: string;
    public method: string;

    // File
    public avatarFile: any;
    public busy:boolean = false;

    // Errors
    public errorFile: any;

    // Text
    public text:any;

    public constructor(public $scope:any,
                       public Upload: any,
                       public $timeout:any,
                       public NotificationsService:any,
                       public $window:any,
                       public I18n:op.I18n) {
        this.text = {
            label_choose_avatar: I18n.t('js.avatars.label_choose_avatar'),
            upload_instructions: I18n.t('js.avatars.text_upload_instructions'),
            error_too_large: I18n.t('js.avatars.error_image_too_large'),
            wrong_file_format: I18n.t('js.avatars.wrong_file_format'),
            button_update: I18n.t('js.button_update'),
            preview: I18n.t('js.label_preview')
        }
    }

    public $onInit() {

    }

    public get isInvalid() {
        if (this.formFile.$pristine) {
            return false;
        }

        return this.formFile.$invalid;
    }

    public get formFile() {
        return this.form.avatar;
    }

    public uploadAvatar(evt:any) {
        evt.preventDefault();
        this.busy = true;
        this.Upload.upload({
            url: this.target,
            method: this.method,
            data: {avatar: this.avatarFile},
        }).then(() => {
            this.$timeout(() => {
                this.$window.location.reload();
            });
        }, (response:any) => {
            if (response.status > 0) {
                this.NotificationsService.addError(response.data);
                this.busy = false;
            }
        }, (evt:ProgressEvent) => {
            // Math.min is to fix IE which reports 200% sometimes
            this.avatarFile.progress = 100.0 * evt.loaded / evt.total;
        });

        return false;
    }
}

angular.module('openproject').component('avatarUploadForm', {
    templateUrl: '/templates/plugin-avatars/avatar-upload-form.html',
    controller: AvatarUploadFormController,
    require : {
        form : '^'
    },
    bindings: {
        target: '@',
        method: '@'
    }
});
