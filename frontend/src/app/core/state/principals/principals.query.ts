import { QueryEntity } from '@datorama/akita';
import { Observable } from 'rxjs';
import { IPrincipal } from './principal.model';
import { PrincipalsState } from './principals.store';

export class PrincipalsQuery extends QueryEntity<PrincipalsState> {
  public byIds(ids:string[]):Observable<IPrincipal[]> {
    return this.selectMany(ids);
  }
}
