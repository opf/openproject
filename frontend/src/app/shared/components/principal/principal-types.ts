import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { PlaceholderUserResource } from 'core-app/features/hal/resources/placeholder-user-resource';
import { GroupResource } from 'core-app/features/hal/resources/group-resource';

export type PrincipalLike =
  UserResource
  |PlaceholderUserResource
  |GroupResource
  |{ id?:string, name:string, href?:string };

export interface PrincipalData {
  principal:PrincipalLike|null;
  customFields:{ [key:string]:any },
}
