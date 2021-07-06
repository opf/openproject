import { Injectable } from '@angular/core';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { input } from 'reactivestates';
import { Observable } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { Board } from 'core-app/features/boards/board/board';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

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
        map((results) => {
          if (matching) {
            return results.filter((resource) => new RegExp(matching, 'i').test(resource.name));
          }
          return results;
        }),
        take(1),
      );
  }

  addColumnWithActionAttribute(board:Board, value:HalResource):Promise<Board> {
    if (this.cache.value) {
      // Add the new value to the cache
      const newValue = [...this.cache.value, value];
      this.cache.putValue(newValue);
    }

    return super.addColumnWithActionAttribute(board, value);
  }

  protected require(id:string):Promise<HalResource> {
    this
      .cache
      .putFromPromiseIfPristine(() => this.loadUncached());

    return this
      .cache
      .values$()
      .pipe(
        take(1),
      )
      .toPromise()
      .then((results) => results.find((resource) => resource.id === id)!);
  }

  protected abstract loadUncached():Promise<HalResource[]>;
}
