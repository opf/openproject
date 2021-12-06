import {
  action,
  props,
} from 'ts-action';
import { ID } from '@datorama/akita';

export const itemAddedToQuerySpace = action(
  '[Partitioned query space] New item added to view',
  props<{ workPackages:ID[] }>(),
);
