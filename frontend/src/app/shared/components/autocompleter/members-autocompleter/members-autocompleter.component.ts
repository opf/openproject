import { firstValueFrom, Observable } from 'rxjs';
import { HttpParams } from '@angular/common/http';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, inject, Input, OnInit } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  IUserAutocompleteItem,
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { URLParamsEncoder } from 'core-app/features/hal/services/url-params-encoder';
import { PrincipalType } from 'core-app/shared/components/principal/principal-helper';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { map } from 'rxjs/operators';
import { ID } from '@datorama/akita';

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class MembersAutocompleterComponent extends UserAutocompleterComponent implements OnInit {
  @Input() principalType?:PrincipalType;

  readonly pathHelper = inject(PathHelperService);
  readonly currentUser = inject(CurrentUserService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly cdRef = inject(ChangeDetectorRef);

  ngOnInit() {
    super.ngOnInit();

    if (this.principalType === 'placeholder_user') {
      this
        .currentUser
        .hasCapabilities$('placeholder_users/create', 'global')
        .subscribe((canCreate) => {
          if (canCreate) {
            this.addTag = this.createPlaceholderUser.bind(this);
            this.addTagText = this.I18n.t('js.invite_user_modal.placeholder_add_tag');
            this.cdRef.markForCheck();
          }
        });
    }
  }

  public createPlaceholderUser(searchTerm:string):Promise<IUserAutocompleteItem> {
    const request = this
      .apiV3Service
      .placeholder_users
      .post({ name: searchTerm })
      .pipe(
        map((principal) => {
          return {
            id: principal.id as ID,
            name: principal.name,
            href: principal.href,
          };
        }),
      );

    return firstValueFrom(request);
  }

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
