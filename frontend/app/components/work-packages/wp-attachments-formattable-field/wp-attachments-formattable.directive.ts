import {WpAttachmentsService} from './../wp-attachments/wp-attachments.service';
import {InsertMode, ViewMode} from './wp-attachments-formattable.enums';
import {
  DropModel,
  EditorModel,
  MarkupModel,
  FieldModel,
  SingleAttachmentModel
} from './wp-attachments-formattable.models';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageSingleViewController} from '../wp-single-view/wp-single-view.directive';
import {WorkPackageEditFormController} from '../../wp-edit/wp-edit-form.directive';
import {openprojectModule} from '../../../angular-modules';

export class WpAttachmentsFormattableController {
  private viewMode:ViewMode = ViewMode.SHOW;

  constructor(protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery,
              protected $rootScope:ng.IRootScopeService,
              protected $location:ng.ILocationService,
              protected wpAttachments:WpAttachmentsService,
              protected $timeout:ng.ITimeoutService) {

    $element.on('drop', this.handleDrop);
    $element.on('dragenter dragleave dragover', this.prevDefault);

  }

  public handleDrop = (evt:DragEvent):void => {
    evt.preventDefault();
    evt.stopPropagation();

    const textarea:ng.IAugmentedJQuery = this.$element.find('textarea');
    this.viewMode = (textarea.length > 0) ? ViewMode.EDIT : ViewMode.SHOW;

    const workPackage:WorkPackageResourceInterface = (this.$scope as any).workPackage;
    const dropData:DropModel = new DropModel(this.$location, evt.originalEvent.dataTransfer, workPackage);

    var description:any;

    if (this.viewMode === ViewMode.EDIT) {
      description = new EditorModel(textarea, new MarkupModel());
    }
    else {
      description = new FieldModel(workPackage, new MarkupModel());
    }

    if (angular.isUndefined(dropData.webLinkUrl) && angular.isUndefined(dropData.files)) {
      return;
    }

    if (dropData.isUpload) {
      if (dropData.filesAreValidForUploading()) {
        if (!dropData.isDelayedUpload) {
          this.wpAttachments.upload(workPackage, dropData.files).then(() => {
            this.wpAttachments.load(workPackage, true).then((updatedAttachments:any) => {
              if (angular.isUndefined(updatedAttachments)) {
                return;
              }

              updatedAttachments.sort(function (a, b) {
                return a.id > b.id ? 1 : -1;
              });

              if (dropData.filesCount === 1) {
                const currentFile:SingleAttachmentModel =
                  new SingleAttachmentModel(updatedAttachments[updatedAttachments.length - 1]);
                description.insertAttachmentLink(
                  currentFile.url,
                  (currentFile.isAnImage) ? InsertMode.INLINE : InsertMode.ATTACHMENT);
              }
              else if (dropData.filesCount > 1) {
                for (let i:number = updatedAttachments.length - 1;
                     i >= updatedAttachments.length - dropData.filesCount;
                     i--) {
                  description.insertAttachmentLink(
                    updatedAttachments[i]._links.downloadLocation.href,
                    InsertMode.ATTACHMENT,
                    true);
                }
              }
              description.save();
            }, err => {
              console.log('error while reloading attachments', err);
            });
          }, function (err) {
            console.log(err);
          });
        } else {
          dropData.files.forEach((file:File) => {
            description.insertAttachmentLink(file.name.replace(/ /g, '_'), InsertMode.ATTACHMENT, true);
            file['isPending'] = true;
            this.wpAttachments.attachments.push(file);
          });
          description.save();
        }
      }
    } else {
      const insertUrl:string = dropData.isAttachmentOfCurrentWp() ? dropData.removeHostInformationFromUrl() : dropData.webLinkUrl;
      const insertAlternative:InsertMode = dropData.isWebImage() ? InsertMode.INLINE : InsertMode.LINK;
      const insertMode:InsertMode = dropData.isAttachmentOfCurrentWp() ? InsertMode.ATTACHMENT : insertAlternative;

      description.insertWebLink(insertUrl, insertMode);
      description.save();
    }
  };

  protected prevDefault(evt:DragEvent):void {
    evt.preventDefault();
    evt.stopPropagation();
  }
}

interface IAttachmentScope extends ng.IScope {
  workPackage:WorkPackageResourceInterface;
}

function wpAttachmentsFormattable() {
  return {
    bindToController: true,
    controller: WpAttachmentsFormattableController,
    link: (scope:IAttachmentScope,
           element:ng.IAugmentedJQuery,
           attrs:ng.IAttributes,
           controllers:[WorkPackageSingleViewController, WorkPackageEditFormController]) => {
      // right now the attachments directive will only work in combination with either
      // the wpSingleView or the wpEditForm directive
      // else the drop handler will fail because of a missing reference to the current wp
      if (angular.isUndefined(controllers[0] && angular.isUndefined(controllers[1]))) {
        return;
      }

      scope.workPackage = !controllers[0] ? controllers[1].workPackage : controllers[0].workPackage;
    },
    require: ['?^wpSingleView', '?^wpEditForm'],
    restrict: 'A'
  };
}

openprojectModule.directive('wpAttachmentsFormattable', wpAttachmentsFormattable);
