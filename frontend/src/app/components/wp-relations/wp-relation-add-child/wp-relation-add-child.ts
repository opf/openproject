import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {Component, ElementRef, EventEmitter, Inject, Input, OnInit, Output} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

@Component({
  selector: 'wp-relation-add-child',
  template: require('!!raw-loader!./wp-relation-add-child.html')
})
export class WpRelationAddChildComponent implements OnInit {
  @Input() public workPackage:WorkPackageResource;
  @Output() public onAdded = new EventEmitter<string>();

  public showRelationsCreateForm: boolean = false;

  public isDisabled = false;
  public canAddChildren:boolean = false;
  public canLinkChildren:boolean = false;
  public selectedWpId:string|null = null;

  public text = {
    save: this.I18n.t('js.relation_buttons.save'),
    abort: this.I18n.t('js.relation_buttons.abort'),
    addNewChild: this.I18n.t('js.relation_buttons.add_new_child'),
    addExistingChild: this.I18n.t('js.relation_buttons.add_existing_child')
  };

  private $element:JQuery;

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              readonly elementRef:ElementRef,
              protected wpRelations:WorkPackageRelationsService,
              protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpCacheService:WorkPackageCacheService) {
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.canAddChildren = !!this.workPackage.addChild;
    this.canLinkChildren = !!this.workPackage.changeParent;
  }

  public updateSelectedId(workPackageId:string) {
    this.selectedWpId = workPackageId;
  }

  public addExistingChild() {
    if (_.isNil(this.selectedWpId)) {
      return;
    }

    const newChildId = this.selectedWpId;
    this.isDisabled = true;

    this.wpRelationsHierarchyService
      .addExistingChildWp(this.workPackage, newChildId)
      .then(() => {
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
        this.isDisabled = false;
        this.onAdded.emit(newChildId);
        this.toggleRelationsCreateForm();
      })
      .catch(err => {
        this.wpNotificationsService.handleErrorResponse(err, this.workPackage);
        this.isDisabled = false;
        this.toggleRelationsCreateForm();
      });
  }

  public createNewChildWorkPackage() {
    this.wpRelationsHierarchyService.addNewChildWp(this.workPackage);
  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;

    setTimeout(() => {
      if (!this.showRelationsCreateForm) {
        this.selectedWpId = null;
        this.$element.find('.-focus-after-save').first().focus();
      }
    });
  }
}
