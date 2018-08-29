import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';

export function workPackagePrefix(workPackageId:string) {
  return `__tl-relation-${workPackageId}`;
}

export class TimelineRelationElement {

  constructor(public belongsToId:string, public relation:RelationResource) {
  }

  public get classNames():string[] {
    return [
      workPackagePrefix(this.relation.ids.from),
      workPackagePrefix(this.relation.ids.to)
    ];
  }

}
