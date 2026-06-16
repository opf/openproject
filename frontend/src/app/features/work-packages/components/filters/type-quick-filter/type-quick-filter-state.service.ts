import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class TypeQuickFilterStateService {
  private _selectedTypeHrefs$ = new BehaviorSubject<Set<string>>(new Set());

  readonly selectedTypeHrefs$ = this._selectedTypeHrefs$.asObservable();

  get current():Set<string> { return this._selectedTypeHrefs$.value; }

  update(ids:Set<string>):void {
    this._selectedTypeHrefs$.next(ids);
  }

  isActive():boolean { return this._selectedTypeHrefs$.value.size > 0; }
}
