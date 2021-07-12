import { Observable } from 'rxjs';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Component } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  UserAutocompleteItem,
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { URLParamsEncoder } from 'core-app/features/hal/services/url-params-encoder';

export const membersAutocompleterSelector = 'members-autocompleter';

@Component({
  templateUrl: '../user-autocompleter/user-autocompleter.component.html',
  selector: membersAutocompleterSelector,
})
export class MembersAutocompleterComponent extends UserAutocompleterComponent {
  @InjectField() http:HttpClient;

  @InjectField() pathHelper:PathHelperService;

  protected getAvailableUsers(url:string, searchTerm:any):Observable<UserAutocompleteItem[]> {
    return this.http
      .get<UserAutocompleteItem[]>(url,
      {
        params: new HttpParams({ encoder: new URLParamsEncoder(), fromObject: { q: searchTerm } }),
        responseType: 'json',
        headers: { 'Content-Type': 'application/json; charset=utf-8' },
      });
  }
}
