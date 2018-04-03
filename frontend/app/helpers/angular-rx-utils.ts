// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import IScope = angular.IScope;
import {Observable} from 'rxjs/Observable';
import {Observer} from 'rxjs/Observer';

export function runInScopeDigest(scope:IScope, fn:() => void) {
  if (scope.$root.$$phase !== '$apply' && scope.$root.$$phase !== '$digest') {
    scope.$apply(fn);
  } else {
    fn();
  }
}

export function scopedObservable<T>(scope:IScope, observable:Observable<T>):Observable<T> {
  return Observable.create((observer:Observer<T>) => {
    var disposable = observable.subscribe(
      value => {
        runInScopeDigest(scope, () => observer.next(value));
      },
      exception => {
        runInScopeDigest(scope, () => observer.error(exception));
      },
      () => {
        runInScopeDigest(scope, () => observer.complete());
      }
    );

    scope.$on('$destroy', () => {
      return disposable.unsubscribe();
    });
  });
}

export function asyncTest<T>(done:(error?:any) => void, fn:(value:T) => any):(T:any) => any {
  return (value:T) => {
    try {
      fn(value);
      done();
    } catch (err) {
      done(err);
    }
  };

}

export function scopeDestroyed$(scope:IScope):Observable<IScope> {
  return Observable.create((s:Observer<IScope>) => {
    scope.$on('$destroy', () => {
      s.next(scope);
      s.complete();
    });
  });
}
