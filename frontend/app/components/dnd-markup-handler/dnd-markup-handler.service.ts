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
  .factory('DndMarkupHandlerService', DndMarkupHandlerService);

function DndMarkupHandlerService($location,
                                 $rootScope,
                                 EditableFieldsState,
                                 WorkPackageService) {

  var _config = {
    enabledFor: ["description"],
    imageFileTypes : ["jpg","jpeg","gif","png"],
    maximumAttachmentFileSize : 0, // initialized during init process from ConfigurationService
    rejectedFileTypes : ["exe"]
  };

  /** DATA MODELS **/

  /**
   * @desc Contains all properties and methods
   * related to the dropevent
   *
   * @param evtDataTransfer
   * @returns {DropModel}
   * @constructor
   */
  var DropModel = function(evtDataTransfer,workPackage){

    var _dt = evtDataTransfer;
    var _self = this;
    var _workPackage = workPackage;

    this.files = _dt.files;
    this.filesCount = _dt.files.length;
    this.isUpload = _isUpload();
    this.isDelayedUpload = _workPackage.isNew;
    this.isWebLink = ! this.isUpload;
    this.webLinkUrl = _dt.getData("URL");

    /**
     * @desc checks whether a given URL points to an image file.
     * Will make decision based on the fileExtensions Array at
     * _config.imageFileTypes[]
     * @returns {boolean}
     */
    this.isWebImage = function(){
      if(angular.isDefined(_self.webLinkUrl)){
        return (_config.imageFileTypes.indexOf(_self.webLinkUrl.split(".").pop().toLowerCase()) > -1);
      }
    };

    /**
     * @desc checks whether a drop content can be identified as attachment
     * belonging to the current wp.
     * Will try to handle URLs and file contents.
     * @returns {boolean}
     */
    this.isAttachmentOfCurrentWp = function(){
      if(_self.isWebLink){

        // weblink does not point to our server, so it can't be an attachment
        if(!(_self.webLinkUrl.indexOf($location.host()) > -1) ) return false;

        var isAttachment = false;
        _workPackage.attachments.forEach(function(attachment){
          if(_self.removeHostInformationFromUrl()// make path relative
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
      return _self.webLinkUrl.replace(window.location.origin, "");
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

    this.filesAreValidForUploading = function(){
      // needs: clarifying if rejected filetypes are a wanted feature
      // no filetypes are getting rejected yet
      var allFilesAreValid = true;
      _self.files.forEach(function(file){
        if(file.size > _config.maximumAttachmentFileSize) {
          allFilesAreValid = false;
          return;
        }
      });
      return allFilesAreValid;
    };

    /**
     * @desc checks if the given files object in
     * the dataTransfer property _dt contains files to upload
     * @returns {boolean}
     * @private
     */
    function _isUpload(){
      if (_dt.types && _self.filesCount > 0) {
        for (var i=0; i < _dt.types.length; i++) {
          if (_dt.types[i] == "Files") {
            return true;
          }
        }
      }
      return false;
    }

    return this;
  }

  /**
   * @desc Contains all properties and methods
   * related to interactions with the textarea element
   * @returns {EditorModel}
   * @constructor
   */
  var EditorModel = function(textarea,markupModel) {
    var _currentCaretPosition,
      _contentToInsert = "",

      _markupModel = markupModel,
      _textarea = textarea;

    /**
     * @desc inserts any link to the editor
     * @param {string} url - link that should be inserted
     * @param insertMode {string} - expected: "ATTACHMENT","INLINE","LINK". Default: "LINK"
     */
    this.insertWebLink = function (url, insertMode) {
      if (angular.isUndefined(insertMode)) insertMode = "LINK";
      _contentToInsert = _markupModel.createMarkup(url, insertMode);
    };

    /**
     * @desc inserts any attachment to the editor
     * @param {string} url - link to the attachment
     * @param {string} insertMode  - expected: "ATTACHMENT","INLINE". Default: "ATTACHMENT"
     * @param {boolean} addLineBreak - in case we have multiple files on our upload queue,
     * we want them to be on a new line each.
     */
    this.insertAttachmentLink = function (url, insertMode, addLineBreak) {
      if (angular.isUndefined(insertMode)) insertMode = "ATTACHMENT";
      _contentToInsert = (addLineBreak) ?
      _contentToInsert + _markupModel.createMarkup(url, insertMode, addLineBreak) :
        _markupModel.createMarkup(url, insertMode, addLineBreak);
    };

    /**
     * @desc remembers the current caret position where
     * our attachment(s) should be inserted to.
     * @param {int} pos - current caret position
     */
    this.setCaretPosition = function () {
      _currentCaretPosition = _textarea[0].selectionStart;
    };

    /**
     * @desc inserts the markup stored in "_contentToInsert" to
     */
    this.save = function () {
      $(_textarea).val(_textarea[0].value.substring(0, _currentCaretPosition) +
        _contentToInsert +
        _textarea[0].value.substring(_currentCaretPosition, _textarea[0].value.length)).change();
    };

    return this;

  }

  /**
   * @desc contains all properties and methods needed for
   * appending attachments to the content of wp fields without
   * opening the INLINE editor
   * @param {string} content - the markup for the attachments,
   * that should get inserted
   * @returns {FieldModel}
   * @constructor
   */
  var FieldModel = function(markupModel,workPackage){
    var _markupModel = markupModel;
    var _workPackage = workPackage;
    var _tempFieldValue = {
      "lockVersion": _workPackage.props.lockVersion,
      "description": {
        "format": "textile",
        "raw": (_workPackage.props.description.raw === null) ? "" : _workPackage.props.description.raw
      }
    };
    var _workPackage = EditableFieldsState.workPackage;

    var _addInitialLineBreak = function(){
      return (_workPackage.props.description.raw === null && _tempFieldValue.description.raw == "")
    };

    this.insertAttachmentLink = function(url,insertMode, addLineBreak){
      var insertString = (_addInitialLineBreak()) ? "" : "\r\n" ;
      _tempFieldValue.description.raw += insertString + _markupModel.createMarkup(url,insertMode,false);
    };

    this.insertWebLink = function(url,insertMode){
      var insertString = (_addInitialLineBreak()) ? "" : "\r\n" ;
      _tempFieldValue.description.raw += insertString + _markupModel.createMarkup(url,insertMode,false);
    };

    this.save = function(){
      $rootScope.$broadcast("dndMarkupHandler.save",_tempFieldValue);
      $rootScope.$broadcast('dndMarkupHandlerDirectiveUpload');
      //EditableFieldsState.isBusy = false;
    };

    return this;
  };

  /**
   * @desc MarkupModel contains all properties and methods to create
   * textile markup for attachments, inline-images and weblinks
   * could be extended via the TextileService for upcoming features
   * @returns {MarkupModel}
   * @constructor
   */
  var MarkupModel = function(){

    /**
     * @desc creates textile markup for links, INLINE images and attachments
     * could get extended to handle more complex markup as well (titles, styles,...)
     * @param {string} insertUrl - the link of our attachment or weblink
     * @param {string} insertMode - can be "ATTACHMENT", "INLINE", "LINK"
     * @param {boolean} addLineBreak - in case we have multiple files on our upload queue,
     * we want them to be on a new line each.
     * @returns {string}
     */
    this.createMarkup = function(insertUrl,insertMode,addLineBreak){

      if (angular.isUndefined((insertUrl))) return "";
      if(angular.isUndefined((addLineBreak))) addLineBreak = false;
      var markup = ""; // init markup as empty string

      switch (insertMode) {
        case "ATTACHMENT":
          markup = "attachment:" + insertUrl.split("/").pop();
          break;
        case "delayedAttachment":
          markup = "attachment:" + insertUrl;
          break;
        case "INLINE":
          markup = "!" + insertUrl + "!";
          break;
        case "LINK":
          markup += insertUrl;
          break;
      }

      if(addLineBreak) markup += "\r\n";
      return markup;
    };

    return this;
  };

  /**
   * @desc contains all properties of a single attachment so it can be evaluated more easily
   * @param attachment
   * @returns {SingleAttachmentModel}
   * @constructor
   */
  var SingleAttachmentModel = function(attachment){

    if(angular.isDefined(attachment)){
      this.fileName = attachment.fileName;
      this.fileExtension = this.fileName.split(".").pop().toLowerCase();

      // for better reusability imageFileTypes could be an argument of SingleAttachmentModel instead
      // of getting the array from _config
      this.isAnImage = (_config.imageFileTypes.indexOf(this.fileExtension) > -1);
      this.url = attachment._links.downloadLocation.href;
    }
    return this;

  };




  return {
    DropModel: DropModel,
    EditorModel: EditorModel,
    FieldModel: FieldModel,
    MarkupModel: MarkupModel,
    SingleAttachmentModel: SingleAttachmentModel,

    uploadQueue: []
  }
}
