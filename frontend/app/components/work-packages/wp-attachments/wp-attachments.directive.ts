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

import {wpDirectivesModule} from "../../../angular-modules";

export class WorkPackageAttachmentsController{
  private editMode: boolean;
  private currentlyFocussing;

  public workPackage: any;

  public test: string = "Hello World";

  public attachments: Array = [];
  public files: Array = [];
  public fetchingConfiguration: boolean = false;
  public loading: boolean = false;

  public hasRightToUpload: boolean = true; // !!(workPackage.links.addAttachment || workPackage.isNew);
  public I18n: any;
  public rejectedFiles: Array = [];
  public size: any;

  public settings: Object = {
    maximumFileSize: Number
  };

  constructor(protected $scope,
              protected $element,
              protected $attrs,
              protected wpAttachments,
              protected NotificationsService,
              protected I18n,
              protected ConfigurationService,
              protected ConversionService){

    this.workPackage = $scope.vm.workPackage();
    this.editMode = $attrs.hasOwnProperty("edit");
    this.I18n = I18n;
    this.wpAttachments = wpAttachments;

    this.attachments = this.wpAttachments.getCurrentAttachments();

    // TODO: why does `this.attachments = this.wpAttachments.getCurrentAttachments();` not bind properly
    // to my Service??
    // meanwhile i present an ultra ultra ugly hack that at least works..
    this.$scope.$watch(() => { return this.wpAttachments.getCurrentAttachments()},(currentAttachments)=>{
      this.attachments = currentAttachments;
    });

    this.fetchingConfiguration = true;
    ConfigurationService.api().then(settings => {
      this.settings.maximumFileSize = settings.maximumAttachmentFileSize;
      this.fetchingConfiguration = false;
    });
    
    this.loadAttachments();

  }

  public upload = () => {
    if (angular.isUndefined(this.files)) { return; }

    if (this.workPackage.isNew) {
      _.each(this.files, (file) => {
        this.attachments.push(file);
      });
      return;
    }

    if (this.files.length > 0) {
      this.wpAttachments.upload(this.workPackage, this.files).then(() => {
        this.files = [];
        this.attachments = [];
        this.loadAttachments();
      });
    }
  };

  public loadAttachments = () => {
    if (this.editMode) {
      this.loading = true;
      this.wpAttachments.load(this.workPackage, true).finally(() => {
        this.loading = false;
      });
    }
  };

  public remove = (file) => {
    if(this.workPackage.isNew){
      _.remove(this.wpAttachments.attachments, file);
    }else{
      this.wpAttachments.remove(file).finally(function () {
        //done
      });
    }
  };

  public focus = (attachment: any) => {
    this.currentlyFocussing = attachment;
  };

  public focussing = (attachment: any) => {
    return this.currentlyFocussing === attachment;
  };

  public filterFiles = (files) => {
    // Directories cannot be uploaded and as such, should not become files in
    // the sense of this directive.  The files within the directories will
    // be taken though.
    _.remove(files, (file:any) => {
      return file.type === 'directory';
    });
  };

  public uploadFilteredFiles = (files) =>{
    this.filterFiles(files);
    this.upload()
  }


}

function wpAttachmentsDirective() {
  return {
    bindToController: true,
    controller: WorkPackageAttachmentsController,
    controllerAs: "vm",
    replace: true,
    restrict: "E",
    scope: {
      workPackage: "&",
    },
    templateUrl: (element, attrs) => {
        return attrs.hasOwnProperty("edit")
          ? "/components/work-packages/wp-attachments/wp-attachments-edit.directive.html"
          : "/components/work-packages/wp-attachments/wp-attachments.directive.html";
    }
  };
}

wpDirectivesModule.directive("wpAttachments", wpAttachmentsDirective);
