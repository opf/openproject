import {UserAutocompleterComponent} from "core-app/modules/common/autocomplete/user-autocompleter.component";
import {Observable} from "rxjs";
import {map} from "rxjs/operators";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {HttpClient} from "@angular/common/http";
import {Component} from "@angular/core";

export const membersAutocompleterSelector = 'members-autocompleter';

@Component({
  templateUrl: '/app/modules/common/autocomplete/user-autocompleter.component.html',
  selector: membersAutocompleterSelector
})
export class MembersAutocompleterComponent extends UserAutocompleterComponent {
  @InjectField() http:HttpClient;

  protected getAvailableUsers(url:string, searchTerm:any):Observable<{[key:string]:string|null}[]> {
    return this.http
      .get(url,
        { params: { q: searchTerm },
          responseType: 'json',
          headers: { 'Content-Type': 'application/json; charset=utf-8' }},
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
