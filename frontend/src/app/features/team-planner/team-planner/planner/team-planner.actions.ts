import { ID } from '@datorama/akita';
import {
  action,
  props,
} from 'ts-action';

export const teamPlannerEventRemoved = action(
  '[Team planner] Event removed from team planner',
  props<{ workPackage:ID }>(),
);

export const teamPlannerEventAdded = action(
  '[Team planner] External event added to the team planner',
  props<{ workPackage:ID }>(),
);

export const teamPlannerPageRefresh = action(
  '[Team planner] Refresh team planner page due to external param changes',
  props<{ showLoading:boolean }>(),
);
