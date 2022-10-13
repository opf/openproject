import { IUser } from './user.model';
import { IGroup } from './group.model';
import { IPlaceholderUser } from './placeholder-user.model';

export type IPrincipal = IUser|IGroup|IPlaceholderUser;
