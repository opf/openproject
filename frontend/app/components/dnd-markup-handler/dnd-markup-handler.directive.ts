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
  .directive('dndMarkupHandler', dndMarkupHandler);

function dndMarkupHandler($rootScope,
                          ConfigurationService,
                          DndMarkupHandlerService,
                          EditableFieldsState,
                          NotificationsService,
                          WorkPackageAttachmentsService) {

  return{
    restrict: 'A',
    link: link
  };

  function link(scope,element,attrs){

    /** SHARED SCOPE PROPERTIES **/
    scope.config = {
      enabledFor: ["description"],
      imageFileTypes : ["jpg","jpeg","gif","png"],
      maximumAttachmentFileSize : 0, // initialized during init process from ConfigurationService
      rejectedFileTypes : ["exe"]
    };

    scope.viewMode = "SHOW"; // (enum)["SHOW","EDIT"]
    scope.workPackage = EditableFieldsState.workPackage;


    /**
     * directive should only be linked right now if field type is description
     * could be extended to other field types
     */
    if(attrs["dndMarkupHandlerFieldName"] != "description")
      return false;

    /**
     * @desc loads wp Attachments from WorkPackageAttachmentService
     * @returns {promise}
     */
    var loadWorkPackageAttachments = function() {
      return WorkPackageAttachmentsService.load(scope.workPackage);
    };

    /**
     * @desc loads main OP config from ConfigurationService
     * @param attachments - attachment data from loadWorkPackageAttachments
     * @returns {promise}
     */
    var loadConfig = function(attachments){
      if(angular.isDefined(attachments)){
        scope.workPackage.attachments = attachments;
      }
      return ConfigurationService.api();
    };

    /**
     * @desc init wp attachments and config
     * broadcasts "AllAsyncDataReady" when everything went fine
     */
    if(WorkPackageAttachmentsService && angular.isDefined(scope.workPackage) && !scope.workPackage.isNew){
      loadWorkPackageAttachments()
        .then(loadConfig)
        .then(function(config){
          scope.config.maximumAttachmentFileSize = config.maximumAttachmentFileSize;
          scope.$broadcast("AllAsyncDataReady");
        });
    }else{
      loadConfig()
        .then(function(config){
          // scope.workPackage.attachments will be undefined
          scope.config.maximumAttachmentFileSize = config.maximumAttachmentFileSize;
          scope.$broadcast("AllAsyncDataReady");
        })
    }


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
    });

    /**
     * let's handle each event separately, so we can extend the behavior of the directive
     * more easily in the future
     * could be simplified in one preventDefault(evt) function.
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
     *    => images will be inserted INLINE
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

      // Get our View-Mode
      var textarea = $(element).find("textarea");
      scope.viewMode = (textarea.length > 0) ? "EDIT" : "SHOW";

      // For better handling of the dropped data
      var dropData = new DndMarkupHandlerService.DropModel(evt.dataTransfer,scope.workPackage);

      // Preparing the markup insertion
      var description;
      if(scope.viewMode == "EDIT"){
        // markup will be created for insert mode and
        // added to the textarea
        description = new DndMarkupHandlerService.EditorModel(textarea,new DndMarkupHandlerService.MarkupModel());
        description.setCaretPosition();
      }else if(scope.viewMode == "SHOW"){
        // markup will be inserted directly to the
        // wp field
        description = new DndMarkupHandlerService.FieldModel(new DndMarkupHandlerService.MarkupModel(),scope.workPackage);
      }

      if (angular.isUndefined(dropData.webLinkUrl) && angular.isUndefined(dropData.files))
        return; // can't process the drop data, so exit the drop method

      // actually handling the dropData
      if (dropData.isUpload) {
        if (dropData.filesAreValidForUploading) {
          if(! dropData.isDelayedUpload){ // add handling for pending uploads (wp creation!)
            WorkPackageAttachmentsService.upload(scope.workPackage, dropData.files).then(function(){
                  WorkPackageAttachmentsService.load(EditableFieldsState.workPackage,true).then(function(updatedAttachments) {

                    // update the list of updatedAttachments on the wp-form
                    // see work-package-updatedAttachments-directive
                    $rootScope.$broadcast("dndMarkupHandlerDirectiveUpload");

                    // in case something goes wrong with fetching the current wp: exit insert
                    // because we won't have a proper URL to the attachment
                    if(angular.isUndefined(updatedAttachments))
                      return;

                    scope.workPackage.attachments = updatedAttachments;

                    // make sure some funny browsers don't mess up our order...
                    scope.workPackage.attachments.sort(function(a,b){
                      return a.id > b.id ? 1 : -1;
                    });

                    // Upload Case: Single File
                    if (dropData.filesCount == 1) {
                      var currentFile = new DndMarkupHandlerService.SingleAttachmentModel(scope.workPackage.attachments.pop());

                      if (currentFile.isAnImage)
                        description.insertAttachmentLink(currentFile.url,"INLINE");
                      else
                        description.insertAttachmentLink(currentFile.url,"ATTACHMENT");
                    }
                    // Upload Case: Multiple Files
                    else {
                      for(var i = scope.workPackage.attachments.length-1;
                          i >= scope.workPackage.attachments.length - dropData.filesCount;
                          i--){
                        description.insertAttachmentLink(scope.workPackage.attachments[i]._links.downloadLocation.href,"ATTACHMENT",true);
                      }
                    }
                    description.save();

                  })
                      .catch(function(ex){
                    NotificationsService.addError("Exception in directive workpackage-dnd-file-handler while reloading attachments.");
                  })
            })
            .catch(function(ex){
                  NotificationsService.addError("Exception in directive workpackage-dnd-file-handler while uploading data.");
                }
            );

          }
          else{
            $rootScope.$broadcast("dndMarkupHandlerAddUploads",evt.dataTransfer.files);
            if(scope.viewMode == "EDIT"){
              console.log("viewmode = edit");
              for(var i = 0; i <= dropData.filesCount-1; i++){
                console.log("insert" + dropData.files[i].name);
                description.insertAttachmentLink(dropData.files[i].name,"ATTACHMENT",true);
              }
              description.save();
            }
          }
        }
      }
      else {

        var insertUrl;

        if(dropData.isWebImage()){

          if(dropData.isAttachmentOfCurrentWp())
            insertUrl = dropData.removeHostInformationFromUrl();
          else
            insertUrl = dropData.webLinkUrl;
          description.insertWebLink(insertUrl,"INLINE");
        }
        else{
          insertUrl = dropData.webLinkUrl;
          var insertMode = "LINK";
          if(dropData.isAttachmentOfCurrentWp()){
            insertUrl = dropData.removeHostInformationFromUrl();
            insertMode = "ATTACHMENT";
          }
          description.insertWebLink(insertUrl,insertMode);
        }
        description.save();
      }

    }
  }



}
