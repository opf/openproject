export type ChangeItem = {
  from:unknown;
  to:unknown;
};
export type ChangeMap = { [attribute:string]:ChangeItem };

export class Changeset {
  private changes:ChangeMap = {};

  /**
   * Return whether a change value exist for the given attribute key.
   * @param {string} key
   * @return {boolean}
   */
  public contains(key:string) {
    return this.changes.hasOwnProperty(key);
  }

  /**
   * Get changed attribute names
   * @returns {string[]}
   */
  public get changed():string[] {
    return _.keys(this.changes);
  }

  /**
   * Returns the live set of the changes.
   */
  public get all():ChangeMap {
    return this.changes;
  }

  /**
   * Reset one or multiple changes
   * @param key
   */
  public reset(...keys:string[]) {
    keys.forEach((k) => {
      delete this.changes[k];
    });
  }

  /**
   * Reset the entire changeset
   */
  public clear():void {
    this.changes = {};
  }

  public set(key:string, value:unknown, pristineValue:unknown):void {
    this.changes[key] = {
      from: pristineValue,
      to: value
    };
  }

  /**
   * Get a change item for the given key, if any
   * @param key
   */
  public getItem(key:string):ChangeItem|undefined {
    return this.changes[key];
  }

  /**
   * Get a single value from the changeset
   * @param key
   */
  public getValue(key:string):unknown|undefined {
    return this.getItem(key)?.to;
  }

  /**
   * Get a single pristine value from the changeset
   * @param key
   */
  public getPristine(key:string):unknown|undefined {
    return this.changes[key]?.from;
  }
}
