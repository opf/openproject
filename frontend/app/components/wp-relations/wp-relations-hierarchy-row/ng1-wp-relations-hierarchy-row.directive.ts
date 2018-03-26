// This Angular directive will act as an interface to the "upgraded" AngularJS component
// query-filters
import {
  Directive,
  DoCheck,
  ElementRef,
  Inject,
  Injector,
  Input,
  OnChanges,
  OnDestroy,
  OnInit
} from '@angular/core';
import {UpgradeComponent} from '@angular/upgrade/static';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';

@Directive({selector: 'ng1-wp-relations-hierarchy-row'})
export class Ng1RelationsHierarchyRowWrapper extends UpgradeComponent implements OnInit, OnChanges, DoCheck, OnDestroy {
  @Input('workPackage') workPackage:WorkPackageResourceInterface;
  @Input('relatedWorkPackage') relatedWorkPacakge:WorkPackageResourceInterface;
  @Input('relationType') relationType:string;
  @Input('indentBy') indentBy?:string;

  constructor(@Inject(ElementRef) elementRef:ElementRef, @Inject(Injector) injector:Injector) {
    // We must pass the name of the directive as used by AngularJS to the super
    super('wpRelationsHierarchyRow', elementRef, injector);
  }
}

