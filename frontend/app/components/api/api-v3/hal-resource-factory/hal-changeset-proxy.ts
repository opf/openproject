export interface ChangesetProxy {
  changesetReset():void;

  changesetPersist():void;
}

export function createChangeSetProxy<T>(target:T):T & ChangesetProxy {
  const proxy = {} as any;
  Object.setPrototypeOf(proxy, target);

  proxy.changesetReset = () => {
    _.forOwn(proxy, (value, key) => delete proxy[key!]);
  };

  proxy.changesetPersist = () => {
    _.forOwn(proxy, (value, key) => {
      (target as any)[key!] = value;
      delete proxy[key!];
    });
  };

  return proxy as any;
}
