import {UserAutocompleterComponent} from "core-app/modules/common/autocomplete/user-autocompleter.component";
import {Observable} from "rxjs";
import {map} from "rxjs/operators";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {HttpClient, HttpParams} from "@angular/common/http";
import {Component} from "@angular/core";
import {URLParamsEncoder} from "core-app/modules/hal/services/url-params-encoder";

export const membersAutocompleterSelector = 'members-autocompleter';

@Component({
  templateUrl: '/app/modules/common/autocomplete/user-autocompleter.component.html',
  selector: membersAutocompleterSelector
})
export class MembersAutocompleterComponent extends UserAutocompleterComponent {
  @InjectField() http:HttpClient;

  protected getAvailableUsers(url:string, searchTerm:any):Observable<{ [key:string]:string|null }[]> {
    return this.http
      .get(url,
        {
          params: new HttpParams({ encoder: new URLParamsEncoder(), fromObject: { q: searchTerm } }),
          responseType: 'json',
          headers: { 'Content-Type': 'application/json; charset=utf-8' }
        },
      )
      .pipe(
        map((res:any) => {
          return res.results.items.map((el:any) => {
            return { name: el.name, id: el.id, href: el.id };
          });
        })
      );
  }
}
