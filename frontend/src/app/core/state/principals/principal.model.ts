import { User } from './user.model';
import { Group } from './group.model';
import { PlaceholderUser } from './placeholder-user.model';

export type Principal = User|Group|PlaceholderUser;
