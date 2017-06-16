import {RelationResource} from "../../../api/api-v3/hal-resources/relation-resource.service";

export function workPackagePrefix(workPackageId: string) {
  return `__tl-relation-${workPackageId}`;
}

export class TimelineRelationElement {

  constructor(public belongsToId: string, public relation: RelationResource) {
  }

  public get classNames(): string[] {
    return [
      workPackagePrefix(this.relation.ids.from),
      workPackagePrefix(this.relation.ids.to)
    ];
  }

}
