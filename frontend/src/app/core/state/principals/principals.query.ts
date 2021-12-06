import { QueryEntity } from '@datorama/akita';
import { PrincipalsState } from './principals.store';

export class PrincipalsQuery extends QueryEntity<PrincipalsState> {
  public byIds(ids:string[]) {
    return this.selectMany(ids);
  }
}
