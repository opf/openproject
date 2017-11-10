import {InjectionToken} from '@angular/core';

export const I18nToken = new InjectionToken<op.I18n>('I18n');


export function upgradeService(ng1InjectorName:string, providedType:any) {
  return {
    provide: providedType,
    useFactory: (i:any) => i.get(ng1InjectorName),
    deps: ['$injector']
  };
}

export function upgradeServiceWithToken(ng1InjectorName:string, token:InjectionToken<any>) {
  return {
    provide: token,
    useFactory: (i:any) => i.get(ng1InjectorName),
    deps: ['$injector']
  };
}
