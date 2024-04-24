import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export function halHref<T extends HalResource>(_index:number, item:T):string|null {
  return item.href;
}

export function compareByAttribute(...attributes:string[]) {
  return (a:any, b:any) => {
    const bothNil = !a && !b;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    const same = !!a && !!b && attributes.every((attribute) => a[attribute] === b[attribute]);
    return bothNil || (!!a && !!b && same);
  };
}

export function compareByName<T extends HalResource>(a:T|undefined|null, b:T|undefined|null):boolean {
  return compareByAttribute('name')(a, b);
}

export function trackByName(i:number, item:any) {
  return _.get(item, 'name');
}

export function trackByHref(i:number, item:{ href?:unknown }) {
  return _.get(item, 'href');
}

export function trackByProperty(prop:string) {
  return (i:number, item:unknown) => _.get(item, prop);
}

export function trackByHrefAndProperty(propertyName:string) {
  return (i:number, item:HalResource) => {
    const href:string = _.get(item, 'href') || '';
    const prop:string = _.get(item, propertyName, 'none');

    return `${href}#${propertyName}=${prop}`;
  };
}

export function trackByTrackingIdentifier(i:number, item:any) {
  return _.get(item, 'trackingIdentifier', item && item.href);
}

export function compareByHref<T extends HalResource>(a:T|undefined|null, b:T|undefined|null):boolean {
  const bothNil = !a && !b;
  return bothNil || (!!a && !!b && a.href === b.href);
}

export function compareByHrefOrString<T extends HalResource>(a:T|string|undefined|null|unknown, b:T|string|undefined|null|unknown):boolean {
  if (a instanceof HalResource && b instanceof HalResource) {
    return compareByHref(a, b);
  }

  const bothNil = !a && !b;
  return bothNil || a === b;
}
