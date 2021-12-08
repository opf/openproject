import { QueryEntity } from '@datorama/akita';
import { Observable } from 'rxjs';
import { Principal } from './principal.model';
import { PrincipalsState } from './principals.store';

export class PrincipalsQuery extends QueryEntity<PrincipalsState> {
  public byIds(ids:string[]):Observable<Principal[]> {
    return this.selectMany(ids);
  }
}
