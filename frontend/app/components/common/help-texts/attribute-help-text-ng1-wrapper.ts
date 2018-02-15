// This Angular directive will act as an interface to the "upgraded" AngularJS component
// query-filters
import {
  Directive, DoCheck, ElementRef, Inject, Injector, Input, OnChanges, OnDestroy,
  OnInit, SimpleChanges
} from '@angular/core';
import {UpgradeComponent} from '@angular/upgrade/static';

@Directive({selector: 'ng1-attribute-help-text-wrapper'})
export class Ng1AttributeHelpTextWrapper extends UpgradeComponent implements OnInit, OnChanges, DoCheck, OnDestroy {
  @Input('attribute') public attribute:string;
  @Input('attributeScope') public attributeScope:string;
  @Input('helpTextId') public helpTextId?:string;
  @Input('additionalLabel') public additionalLabel?:string;

  constructor(@Inject(ElementRef) elementRef:ElementRef, @Inject(Injector) injector:Injector) {
    // We must pass the name of the directive as used by AngularJS to the super
    super('attributeHelpText', elementRef, injector);
  }

  // For this class to work when compiled with AoT, we must implement these lifecycle hooks
  // because the AoT compiler will not realise that the super class implements them
  ngOnInit() { super.ngOnInit(); }

  ngOnChanges(changes:SimpleChanges) { super.ngOnChanges(changes); }

  ngDoCheck() { super.ngDoCheck(); }

  ngOnDestroy() { super.ngOnDestroy(); }
}
