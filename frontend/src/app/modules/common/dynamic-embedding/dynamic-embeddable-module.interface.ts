import {ComponentType} from "@angular/cdk/portal";

export interface DynamicLazyLoadModule {
  lazyloadableComponents:{ [key:string]:ComponentType<any> };
}
