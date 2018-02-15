// This Angular directive will act as an interface to the "upgraded" AngularJS component
import {
  Directive, DoCheck, ElementRef, Inject, Injector, Input, OnChanges, OnDestroy,
  OnInit, SimpleChanges
} from '@angular/core';
import {UpgradeComponent} from '@angular/upgrade/static';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';

@Directive({selector: 'ng1-wp-subject-wrapper'})
export class Ng1WorkPackageSubjectComponentWrapper extends UpgradeComponent implements OnInit, OnChanges, DoCheck, OnDestroy {

  @Input('workPackage') workPackage:WorkPackageResourceInterface;

  constructor(@Inject(ElementRef) elementRef:ElementRef, @Inject(Injector) injector:Injector) {
    // We must pass the name of the directive as used by AngularJS to the super
    super('wpSubject', elementRef, injector);
  }

  // For this class to work when compiled with AoT, we must implement these lifecycle hooks
  // because the AoT compiler will not realise that the super class implements them
  ngOnInit() { super.ngOnInit(); }

  ngOnChanges(changes:SimpleChanges) { super.ngOnChanges(changes); }

  ngDoCheck() { super.ngDoCheck(); }

  ngOnDestroy() { super.ngOnDestroy(); }
}
