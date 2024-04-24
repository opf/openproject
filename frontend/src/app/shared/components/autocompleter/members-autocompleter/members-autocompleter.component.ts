import { Observable } from 'rxjs';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HttpParams } from '@angular/common/http';
import { Component } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  IUserAutocompleteItem,
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { URLParamsEncoder } from 'core-app/features/hal/services/url-params-encoder';

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
})
export class MembersAutocompleterComponent extends UserAutocompleterComponent {
  @InjectField() pathHelper:PathHelperService;

  public getAvailableUsers(searchTerm:string):Observable<IUserAutocompleteItem[]> {
    return this
      .http
      .get<IUserAutocompleteItem[]>(
        this.url,
        {
          params: new HttpParams({ encoder: new URLParamsEncoder(), fromObject: { q: searchTerm } }),
          responseType: 'json',
          headers: { 'Content-Type': 'application/json; charset=utf-8' },
        },
      );
  }
}
