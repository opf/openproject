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

export function trackByHrefAndProperty(propertyName:string) {
  return (i:number, item:HalResource) => {
    const href:string = item.href ?? '';
    const prop:string = (item as Record<string, string|undefined>)[propertyName] ?? 'none';

    return `${href}#${propertyName}=${prop}`;
  };
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
