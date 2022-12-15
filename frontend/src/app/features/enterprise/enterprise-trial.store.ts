import {
  Store,
  StoreConfig,
} from '@datorama/akita';
import { IEnterpriseTrial } from 'core-app/features/enterprise/enterprise-trial.model';

export function createInitialState():IEnterpriseTrial {
  return {
    modalOpen: false,
    confirmed: false,
    cancelled: false,
    emailInvalid: false,
  };
}

@StoreConfig({ name: 'enterprise-trial' })
export class EnterpriseTrialStore extends Store<IEnterpriseTrial> {
  constructor() {
    super(createInitialState());
  }
}
