import {WpAttachmentsService} from './../wp-attachments/wp-attachments.service';
import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service'
import {InsertMode, ViewMode} from './wp-attachments-formattable.enums'
import {DropModel, EditorModel, MarkupModel, FieldModel, SingleAttachmentModel} from './wp-attachments-formattable.models'

export class WpAttachmentsFormattableController {
  private viewMode: ViewMode = ViewMode.SHOW;
  private workPackage: WorkPackageResource;
  constructor(protected $scope: ng.IScope,
              protected $element: ng.IAugmentedJQuery,
              protected $q: ng.IQService,
              protected $rootScope: ng.IRootScopeService,
              protected $location: ng.ILocationService,
              protected $timeout: ng.ITimeoutService,
              protected wpAttachments: WpAttachmentsService,
              protected NotificationsService) {

    $element.get(0).addEventListener('drop', this.handleDrop);
    $element.bind('dragenter', this.prevDefault)
      .bind('dragleave', this.prevDefault)
      .bind('dragover', this.prevDefault);

  }

  public handleDrop = (evt: DragEvent): void => {
    evt.preventDefault();
    evt.stopPropagation();

    this.workPackage = this.$scope.workPackage;

    const dropData: DropModel = new DropModel(this.$location, evt.dataTransfer, this.workPackage);
    if (angular.isUndefined(dropData.webLinkUrl) && angular.isUndefined(dropData.files)){
      return; // unable to handle the dropped content
    }

    // Determine if description field is being displayed in editmode or in viewmode
    const textarea: ng.IAugmentedJQuery = this.$element.find('textarea');
    this.viewMode  = (textarea.length > 0) ? ViewMode.EDIT : ViewMode.SHOW;

    // Markup will either be inserted to the Textarea or directly applied to the wp description
    // depending on the viewmode
    var description: any;
    if (this.viewMode === ViewMode.EDIT) {
      description = new EditorModel(textarea, new MarkupModel());
    }
    else {
      description = new FieldModel(this.workPackage, new MarkupModel());
    }

    if(dropData.isUpload){
      if(!dropData.isDelayedUpload) {
        this.uploadFilesImmediately(dropData.files).then(updatedAttachments=>{
          if (dropData.filesCount === 1) {
            this.handleSingleAttachment(description, updatedAttachments);
          }
          else if (dropData.filesCount > 1) {
            this.handleMultipleAttachments(description, dropData, updatedAttachments)
          }
        });
      }
      else {
        this.handleDelayedUploads(description,dropData);
      }
    }
    else {
      // dropped content is not a file / filelist but a weblink
      this.handleDroppedWebContent(description,dropData);
    }

  };

  /**
   * Uploads dropped files and returns an updated list of attachments afterwards
   * @param dropData
   * @returns {IPromise<Array>}
   */
  public uploadFilesImmediately(files: FileList): ng.IPromise<Array> {
    var reloadAttachments = this.$q.defer();
    this.wpAttachments.upload(this.workPackage,files).then(()=>{
      this.reloadAttachments().then(updatedAttachments=>{
        reloadAttachments.resolve(updatedAttachments);
      })
    });
    return reloadAttachments.promise;
  }

  /**
   * When the user creates a new workPackage, uploading the attachments has to be delayed
   * until the wp is saved. Therefore the attachments will only be added to the upload queue
   * of the `wpAttachments`-Service.
   * @param description
   * @param dropData
   */
  public handleDelayedUploads(description: EditorModel, dropData: DropModel){
    dropData.files.forEach((file: File) => {
      description.insertAttachmentLink(file.name.replace(/ /g , '_'), InsertMode.ATTACHMENT, true);
      file['isPending'] = true;
      this.wpAttachments.addPendingAttachments(file);
    });
    description.save();
  }

  public handleDroppedWebContent(description: any,dropData: DropModel){
    const insertUrl: string = dropData.isAttachmentOfCurrentWp() ? dropData.removeHostInformationFromUrl().split("/").pop() : dropData.webLinkUrl;
    const insertAlternative: InsertMode = dropData.isWebImage() ? InsertMode.INLINE : InsertMode.LINK;
    const insertMode: InsertMode = dropData.isAttachmentOfCurrentWp() ? (dropData.isWebImage() ? InsertMode.INLINE : InsertMode.ATTACHMENT) : insertAlternative;

    description.insertWebLink(insertUrl, insertMode);
    description.save();
  }

  /**
   * If single files are dropped, we decide wether to insert them as inline image or as attachment link
   * @param description
   * @param dropData
   * @param updatedAttachments
   */
  public handleSingleAttachment(description: any, updatedAttachments: any): void {
    const currentFile: SingleAttachmentModel = new SingleAttachmentModel(updatedAttachments[updatedAttachments.length - 1]);

    description.insertAttachmentLink(currentFile.url, (currentFile.isAnImage) ? InsertMode.INLINE : InsertMode.ATTACHMENT);
    description.save();
  }

  /**
   * In contrast to single attachments, multiple attachments get insert as attachment link by default
   * indepentent from their file type
   * @param description
   * @param dropData
   * @param updatedAttachments
   */
  public handleMultipleAttachments(description: any,dropData: DropModel,updatedAttachments){
    for (let i: number = updatedAttachments.length - 1;
         i >= updatedAttachments.length - dropData.filesCount;
         i--) {
      description.insertAttachmentLink(
        updatedAttachments[i]._links.downloadLocation.href,
        InsertMode.ATTACHMENT,
        true);
    }
    description.save();
  }

  public reloadAttachments(): ng.IPromise {
    var attachments = this.$q.defer();
    this.wpAttachments.load(this.workPackage,true).then((updatedAttachments: any) => {
      updatedAttachments.sort(function (a, b) {
        return a.id > b.id ? 1 : -1;
      });
      attachments.resolve(updatedAttachments);
    },function(err){
      this.NotificationsService.addError("Error while reloading attachments after Upload");
      attachments.reject(err);
    });
    return attachments.promise;
  }



  protected prevDefault(evt: DragEvent): void {
    evt.preventDefault();
    evt.stopPropagation();
  }
}

function wpAttachmentsFormattable() {
  return {
    bindToController: true,
    controller: WpAttachmentsFormattableController,
    link: function(scope: ng.IScope,
                   element: ng.IAugmentedJQuery,
                   attrs: ng.IAttributes,
                   controllers: Array<ng.IControllerService>){
      // right now the attachments directive will only work in combination with 
      // the wpEditForm directive
      // else the drop handler will fail because of a missing reference to the current wp
      if(angular.isUndefined(controllers[0])){
        return;
      }

      scope.workPackage = controllers[0].workPackage;
    },
    require: ['?^wpEditForm'],
    restrict: 'A'
  };
}

angular
  .module('openproject')
  .directive('wpAttachmentsFormattable', wpAttachmentsFormattable);
