import {UserResource} from "core-app/core/hal/resources/user-resource";
import {PlaceholderUserResource} from "core-app/core/hal/resources/placeholder-user-resource";
import {GroupResource} from "core-app/core/hal/resources/group-resource";

export type PrincipalLike = UserResource|PlaceholderUserResource|GroupResource|{ id?:string, name:string, href?:string };
export interface PrincipalData {
  principal: PrincipalLike|null;
  customFields: {[key:string]: any}, 
}
