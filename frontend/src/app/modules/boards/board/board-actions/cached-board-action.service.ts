import {Injectable} from "@angular/core";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {input} from "reactivestates";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Observable} from "rxjs";
import {filter, map, take} from "rxjs/operators";

@Injectable()
export abstract class CachedBoardActionService extends BoardActionService {
  protected cache = input<HalResource[]>();

  protected loadValues(matching?:string):Observable<HalResource[]> {
    this
      .cache
      .putFromPromiseIfPristine(() => this.loadUncached());

    return this
      .cache
      .values$()
      .pipe(
        map(results => {
          if (matching) {
            return results.filter(resource => resource.name.includes(matching));
          } else {
            return results;
          }
        }),
        take(1)
      );
  }

  protected require(id:string):Promise<HalResource> {
    this
      .cache
      .putFromPromiseIfPristine(() => this.loadUncached());

    return this
      .cache
      .values$()
      .pipe(
        take(1)
      )
      .toPromise()
      .then(results => {
        return results.find(resource => resource.id === id)!;
      });
  }

  protected abstract loadUncached():Promise<HalResource[]>;
}

