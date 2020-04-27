import {Injectable} from "@angular/core";
import {interval} from 'rxjs';
import {startWith, switchMap, filter} from 'rxjs/operators';
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";

const POLLING_INTERVAL = 2000;

@Injectable()
export class QueryUpdatedService {

  constructor(readonly queryDm:QueryDmService) {}

  public monitor(ids:string[]) {
    let time = new Date();

    return interval(POLLING_INTERVAL)
           .pipe(
             startWith(0),
             switchMap(() => {
               let result = this.queryForUpdates(ids, time);

               time = new Date();

               return result;
             }),
             filter((collection) => collection.count > 0)
           );
  }

  private queryForUpdates(ids:string[], updatedAfter:Date) {
    return this.queryDm.list({filters: [["id", "=", ids],
                                                ["updatedAt", "<>d", [updatedAfter.toISOString()]]]});
  }
}
