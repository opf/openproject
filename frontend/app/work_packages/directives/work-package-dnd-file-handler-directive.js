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



/**
 *
 * @ngdoc directive
 * @name openproject.workPackages.directives:workPackageDndFileHandler
 * @restrict A
 * @description
 * Directive for adding drag and drop functionality to textareas regarding attachments of workpackages.
 *
 * Features:
 * Upload Files via "Drag and Drop" while automatically creating
 * textile markup for linking the attachments in the workpackage description
 *
 * If an image (local file or web source) is dropped, the user can choose what kind of markup should be created.
 * Possible insertion options:
 *  inline image
 *  attachment link
 *
 * The user can drag files from the wp attachments list to the textarea to create links to them as well.
 *
 **/
module.exports = function ($rootScope,
                           $q,
                           $stateParams,
                           ConfigurationService,
                           NotificationsService,
                           WorkPackageAttachmentsService,
                           WorkPackageService) {

  return {
    restrict: 'A',
    link: link
  };


  function link(scope, element, attrs) {

    /** SHARED SCOPE PROPERTIES **/
    scope.workPackage = {};
    scope.config = {
      imageFileTypes : ["jpg","jpeg","gif","png"],
      rejectedFileTypes : ["exe"],
      maximumAttachmentFileSize : 0 // initialized during init process from ConfigurationService
    };


    /******************************************************************
     * INITIALIZING WORKPACKAGE DATA AND ATTACHMENTS
     * ****************************************************************
     * TODO:
     * Need to talk to the OpenProject Pros :)
     *
     * Would probably be better to get wp data and attachments as attribute
     * from the controller since they get loaded there anyways and we could
     * avoid duplicate API-Calls here.
     *
     * Possible solution (depending on how the data will be passed):
     *
     * --------------------
     * Example usage in template:
     * <textarea [...]
     *  workpackage-dnd-file-handler-directive
     *    dnd-file-handler-wp = "vm.workpackageDataObject"
     *    dnd-file-handler-attachments = "vm.attachmentsDataObject"></textarea>
     * ****************************************************************
     */

    /**
     * @desc loads workPackageData from WorkPackageService
     * @returns {promise}
     */
    var loadWorkPackage = function() {
      return WorkPackageService.getWorkPackage($stateParams.workPackageId);
    };

    /**
     * @desc loads workPackageData from WorkPackageAttachmentService
     * @param {Object} wp - wp data from loacWorkPackage()
     * @returns {promise}
     */
    var loadWorkPackageAttachments = function(wp) {
      scope.workPackage = wp;
      return WorkPackageAttachmentsService.load(wp);
    };

    /**
     * @desc loads main OP config from ConfigurationService
     * @param attachments - attachment data from loadWorkPackageAttachments
     * @returns {promise}
     */
    var loadConfig = function(attachments){
      scope.workPackage.attachments = attachments;
      return ConfigurationService.api();
    };

    /**
     * make sure everything gets loaded in the right order
     */
    loadWorkPackage()
      .then(loadWorkPackageAttachments)
      .then(loadConfig)
      .then(function(config){
        scope.config.maximumAttachmentFileSize = config.maximumAttachmentFileSize;
        scope.$broadcast("AllAsyncDataReady");
      });

    /**
     * All set, we are good to go!
     */
    scope.$on("AllAsyncDataReady",function(){
      /** ADD EVENT LISTENERS **/
      element.on({
        "dragenter": handleDragEnter,
        "dragover": handleDragOver,
        "dragleave": handleDragLeave,
        "dragend": handleDragEnd,
        "dragexit": handleDragExit
      });
      element[0].addEventListener("drop", handleDrop);

      /**
       * let's handle each event separatly, so we can extend the behavior of the directive
       * more easily in the future
       */
      function handleDragEnter(evt){
        evt.stopPropagation();
        evt.preventDefault();
      }

      function handleDragOver(evt) {
        evt.stopPropagation();
        evt.preventDefault();
      }

      function handleDragLeave(evt) {
        evt.stopPropagation();
        evt.preventDefault();
      }

      function handleDragEnd(evt){
        evt.stopPropagation();
        evt.preventDefault();
      }

      function handleDragExit(evt){
        evt.stopPropagation();
        evt.preventDefault();
      }




      /**
       * @ngdoc method
       * @name handleDrop
       * @function handleDrop
       * @desc handles the drop event on the textarea
       *
       * expects the dropped item to be:
       *  a local file to upload
       *    => images will be inserted inline
       *    => files will be inserted as attachment link
       *        a weblink (URL)
       *    => the directive till try to identify, if the
       *        url points to a wp attachment and include
       *        it properly
       *    => if it can't be identified as attachment
       *        the url will be inserted as external link
       * @param {Event} evt mouseevent to handle
       */
      function handleDrop(evt) {
        evt.stopPropagation();
        evt.preventDefault();

        var dropData = new DropModel(evt.dataTransfer);

        var editor = new EditorModel();
        editor.setCaretPosition(element[0].selectionStart);

        if (angular.isUndefined(dropData.webLinkUrl) && angular.isUndefined(dropData.files))
          return; // can't process the drop data, so exit the function

        if (dropData.isUpload) {

          if (dropData.filesAreValidForUploading) {
            WorkPackageAttachmentsService.upload(scope.workPackage, dropData.files).then(
              WorkPackageAttachmentsService.load(scope.workPackage, true).then(function (attachments) {

                scope.workPackage.attachments = attachments;

                // Upload Case: Single File
                if (dropData.filesCount == 1) {

                  var currentFile = new SingleAttachmentModel(scope.workPackage.attachments[scope.workPackage.attachments.length - 1]);

                  // it's an image, so we let the user decide if he wants to insert it inline or as an attachment
                  if (currentFile.isAnImage)
                    editor.insertAttachmentLink(currentFile.url,"inline");
                  else
                    editor.insertAttachmentLink(currentFile.url);
                }

                // Upload Case: Multiple Files
                else {
                  for(var i = scope.workPackage.attachments.length-1; i >= scope.workPackage.attachments.length - dropData.filesCount; i--){
                    editor.insertAttachmentLink(scope.workPackage.attachments[i]._links.downloadLocation.href,"attachment",true);
                  }
                }

              }))
              .catch(function(ex){
                //** TODO: remove in production! **/
                NotificationsService.addError("Exception in directive workpackage-dnd-file-handler while uploading data.");
              });


          }
        }
        else {

          if(dropData.isWebImage()){

            var modalOptions = {};
            var insertUrl;

            if(dropData.isAttachmentOfCurrentWp())
              insertUrl = dropData.removeHostInformationFromUrl();
            else
              insertUrl = dropData.webLinkUrl;

            editor.insertWebLink(insertUrl,"inline");

          }
          else{
            var insertUrl = dropData.webLinkUrl;
            var insertMode = "link";
            if(dropData.isAttachmentOfCurrentWp()){
              insertUrl = dropData.removeHostInformationFromUrl();
              insertMode = "attachment";
            }
            editor.insertWebLink(insertUrl,insertMode);
          }

        }

      }


    });

    /** DATA MODELS **/

    /**
     * @desc Contains all properties and methods
     * related to the dropevent
     *
     * @param evtDataTransfer
     * @returns {DropModel}
     * @constructor
     */
    function DropModel(evtDataTransfer){

      var self = this;

      var dt = evtDataTransfer;
      var dropModel = new Object();
      this.files = dt.files;
      this.filesCount = dt.files.length;
      this.isUpload = (dt.types != null && (dt.types.indexOf ? dt.types.indexOf('Files') != -1 : dt.types.contains('application/x-moz-file')));
      this.isWebLink = ! this.isUpload;
      this.webLinkUrl = dt.getData("URL");



      /**
       * @desc checks whether a given URL points to an image file.
       * Will make decision based on the fileExtensions Array at
       * scope.config.imageFileTypes[]
       * @returns {boolean}
       */
      this.isWebImage = function(){
        if(angular.isDefined(self.webLinkUrl)){
          return (scope.config.imageFileTypes.indexOf(self.webLinkUrl.split(".").pop()) > -1);
        }
      };

      /**
       * @desc checks wether a drop content can be identified as attachment
       * belonging to the current wp.
       * Will try to handle URLs and file contents.
       * @returns {boolean}
       */
      this.isAttachmentOfCurrentWp = function(){
        if(self.isWebLink){

          // weblink does not point to our server, so it can't be an attachment
          if(!(self.webLinkUrl.indexOf(window.location.origin) > -1) ) return false;

          var isAttachment = false;
          scope.workPackage.attachments.forEach(function(attachment){
            if(self.removeHostInformationFromUrl()// make path relative
                .indexOf(attachment._links.downloadLocation.href) > -1) {
              isAttachment = true;
              return; // end foreach
            }
          });
          return isAttachment;
        }
      };

      /**
       * @desc returns a relative path from a full URL
       *
       *  usecase:
       *  user dropped a weblink to the textarea which can be resolved as a wp attachment
       *  http://127.0.0.1:5000/attachments/22/sample.jpg
       *
       *  dropModel.removeHostInformationFromUrl(ourUrl)
       *  returns: /attachments/22/sample.jpg</p>
       *
       *  <p>which can be included as clean textile attachment markup</p>
       *
       * @returns {string}
       */
      this.removeHostInformationFromUrl = function(){
        return self.webLinkUrl.replace(window.location.origin, "");
      };

      /**
       * @desc checks if there are any files on the current upload
       * queue that are invalid for uploading
       *
       * Reasons for Rejection:
       *  => filesize exceeds the global filesizelimit returned
       *  from ConfigurationService
       *  => fileextension not allowed for uploading (e.g. *.exe)
       * @returns {boolean}
       */
      dropModel.filesAreValidForUploading = function(){
        var allFilesAreValid = true;
        self.files.forEach(function(file){
          if(file.size > scope.config.maximumAttachmentFileSize) {
            allFilesAreValid = false;
            return;
          }
        });
        return allFilesAreValid;
      };

      return this;
    }

    /**
     * @desc Contains all properties and methods
     * related to interactions with the textarea element
     * @returns {EditorModel}
     * @constructor
     */
    function EditorModel(){
      var currentCaretPosition;

      /**
       * @desc inserts any link to the editor
       * @param {string} url - link that should be inserted
       * @param insertMode {string} - expected: "attachment","inline","link". Default: "link"
       */
      this.insertWebLink = function(url,insertMode){
        if(angular.isUndefined(insertMode)) insertMode = "link";
        insertMarkup(createMarkup(url,insertMode));
      };

      /**
       * @desc inserts any attachment to the editor
       * @param {string} url - link to the attachment
       * @param {string} insertMode  - expected: "attachment","inline". Default: "attachment"
       * @param {boolean} addLineBreak - in case we have multiple files on our upload queue,
       * we want them to be on a new line each.
       */
      this.insertAttachmentLink = function(url,insertMode,addLineBreak){
        if(angular.isUndefined(insertMode)) insertMode = "attachment";
        insertMarkup(createMarkup(url,insertMode,addLineBreak));
      };

      /**
       * @desc remembers the current caret position where
       * our attachment(s) should be inserted to.
       * @param {int} pos - current caret position
       */
      this.setCaretPosition = function(pos){
        currentCaretPosition = pos;
      };

      /**
       * @desc creates textile markup for links, inline images and attachments
       * could get extended to handle more complex markup as well (titles, styles,...)
       * @param {string} insertUrl - the link of our attachment or weblink
       * @param {string} insertMode - can be "attachment", "inline", "link"
       * @param {boolean} addLineBreak - in case we have multiple files on our upload queue,
       * we want them to be on a new line each.
       * @returns {string}
       */
      function createMarkup(insertUrl,insertMode,addLineBreak){

        if (angular.isUndefined((insertMode))) return "";
        if(angular.isUndefined((addLineBreak))) addLineBreak = false;
        var markup = ""; // init markup as empty string

        switch (insertMode) {
          case "attachment":
            markup = "attachment:" + insertUrl.split("/").pop();
            break;
          case "inline":
            markup = "!" + insertUrl + "!";
            break;
          case "link":
            markup += insertUrl;
            break;
        }

        if(addLineBreak) markup += "\r\n";
        return markup;
      }

      function insertMarkup(markup){
        $(element).val(element[0].value.substring(0, currentCaretPosition)
          + markup
          + element[0].value.substring(currentCaretPosition, element[0].value.length)).change();
      }

      return this;

    }



    /**
     * @desc conatins all properties of a single attachment so it can be evaluated more easily
     * @param attachment
     * @returns {SingleAttachmentModel}
     * @constructor
     */
    function SingleAttachmentModel(attachment){

      if(angular.isDefined(attachment)){
        this.fileName = attachment.fileName;
        this.fileExtension = this.fileName.split(".").pop();
        this.isAnImage = (scope.config.imageFileTypes.indexOf(this.fileExtension) > -1);
        this.url = attachment._links.downloadLocation.href;
        return this;
      }

    }
  }

};




