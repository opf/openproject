export type ChangeMap = { [attribute:string]:unknown };

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
    keys.forEach((k) => delete this.changes[k]);
  }

  /**
   * Reset the entire changeset
   */
  public clear():void {
    this.changes = {};
  }

  public set(key:string, value:unknown):void {
    this.changes[key] = value;
  }

  /**
   * Get a single value from the changeset
   * @param key
   */
  public get(key:string):unknown|undefined {
    return this.changes[key];
  }
}
