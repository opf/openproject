import {
  ComponentFactoryResolver, ComponentRef,
  Directive,
  Input,
  OnChanges, OnDestroy,
  ViewContainerRef
} from '@angular/core';
import {DynamicBootstrapComponent} from "core-app/modules/common/dynamic-bootstrap/component/dynamic-bootstrap/dynamic-bootstrap.component";

@Directive({
  selector: '[opDynamicBootstrap]'
})
export class DynamicBootstrapDirective implements OnChanges, OnDestroy {
  @Input('opDynamicBootstrap')
  template:string;

  private componentRef:ComponentRef<DynamicBootstrapComponent>;

  constructor(
    private viewContainer:ViewContainerRef,
    private componentFactoryResolver:ComponentFactoryResolver,
  ) { }

  ngOnChanges() {
    this.viewContainer.clear();

    const componentFactory = this.componentFactoryResolver.resolveComponentFactory(DynamicBootstrapComponent);

    this.componentRef = this.viewContainer.createComponent(componentFactory);
    this.componentRef.instance.innerHtml = this.template;
  }

  ngOnDestroy() {
    this.componentRef?.destroy();
  }
}

