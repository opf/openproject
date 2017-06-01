import { RelationResource } from "../../../api/api-v3/hal-resources/relation-resource.service";

export class TimelineRelationElement {
  constructor(public belongsToId:string, public relation:RelationResource) {
  }

  public static workPackagePrefix(workPackageId:string) {
    return `__tl-relation-${workPackageId}`;
  }

  public get prefix():string {
    return TimelineRelationElement.workPackagePrefix(this.belongsToId);
  }

  public get identifier():string {
    return `${this.prefix}-${this.relation.id}`;
  }

  public get classNames():string[] {
    return [this.prefix, this.identifier];
  }
}
