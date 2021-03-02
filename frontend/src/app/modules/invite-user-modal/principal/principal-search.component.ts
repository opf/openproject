import {
  Component,
  Input,
  EventEmitter,
  OnInit,
  Output,
  ElementRef,
} from '@angular/core';
import {FormControl} from "@angular/forms";
import {Observable, BehaviorSubject, combineLatest, forkJoin} from "rxjs";
import {debounceTime, distinctUntilChanged, first, shareReplay, map, switchMap} from "rxjs/operators";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {PrincipalType} from '../invite-user.component';

@Component({
  selector: 'op-ium-principal-search',
  templateUrl: './principal-search.component.html',
})
export class PrincipalSearchComponent extends UntilDestroyedMixin implements OnInit {
  @Input('opFormBinding') principalControl:FormControl;
  @Input() type:PrincipalType;
  @Input() project:any = null;

  @Output() createNew = new EventEmitter<{ name:string }>();

  public input$ = new BehaviorSubject<string>('');
  public input = '';
  public items$:Observable<any[]>;
  public canInviteByEmail$:Observable<boolean>;
  public canCreateNewPlaceholder$:Observable<boolean>;

  public text = {
    alreadyAMember: () => this.I18n.t('js.invite_user_modal.principal.already_member_message', {
      project: this.project?.name,
    }),
    inviteNewUser: this.I18n.t('js.invite_user_modal.principal.invite_user'),
    createNewPlaceholder: this.I18n.t('js.invite_user_modal.principal.create_new_placeholder'),
    noResults: {
      user: this.I18n.t('js.invite_user_modal.principal.no_results_user'),
      placeholder: this.I18n.t('js.invite_user_modal.principal.no_results_placeholder'),
      group: this.I18n.t('js.invite_user_modal.principal.no_results_group'),
    },
  };

  constructor(
    public I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly apiV3Service:APIV3Service,
  ) {
    super();

    this.input$.subscribe((input:string) => {
      this.input = input;
    });

    this.items$ = this.input$
      .pipe(
        this.untilDestroyed(),
        debounceTime(200),
        distinctUntilChanged(),
        switchMap(this.loadPrincipalData.bind(this)),
      );

    this.canInviteByEmail$ = combineLatest(
      this.items$,
      this.input$,
    ).pipe(
      map(([elements, input]) => this.type === 'user' && input?.includes('@') && !elements.find((el:any) => el.email === input)),
    );

    this.canCreateNewPlaceholder$ = combineLatest(
      this.items$,
      this.input$,
    ).pipe(
      map(([elements, input]) => {
        if (this.type !== PrincipalType.Placeholder) {
          return false;
        }

        return !!input && !elements.find((el:any) => el.name === input);
      }),
    );
  }

  ngOnInit() {
    // Make sure we have initial data
    setTimeout(() => this.input$.next(''));
  }

  createNewFromInput() {
    this.createNew.emit({ name: this.input });
  }

  private loadPrincipalData(searchTerm:string) {
    const type = {
      placeholder: 'PlaceholderUser',
      user: 'User',
      group: 'Group',
    }[this.type];

    const nonMemberFilter = new ApiV3FilterBuilder();
    if (searchTerm) {
      nonMemberFilter.add('name', '~', [searchTerm]);
    }
    nonMemberFilter.add('status', '!', [3]);
    nonMemberFilter.add('type', '=', [type]);
    nonMemberFilter.add('member', '!', [this.project?.id]);

    const memberFilter = new ApiV3FilterBuilder();
    if (searchTerm) {
      memberFilter.add('name', '~', [searchTerm]);
    }
    memberFilter.add('status', '!', [3]);
    memberFilter.add('type', '=', [type]);
    nonMemberFilter.add('member', '=', [this.project?.id]);
    const members = this.apiV3Service.principals.filtered(memberFilter).get();
    const nonMembers = this.apiV3Service.principals.filtered(nonMemberFilter).get();

    return forkJoin({
      members,
      nonMembers,
    })
      .pipe(
        map(({ members, nonMembers }) => [
          ...members.elements.map((member:any) => ({
            ...member,
            disabled: false,
          })),
          ...nonMembers.elements.map((nonMember:any) => ({
            ...nonMember,
            disabled: true,
          })),
        ]),
        shareReplay(1),
      );

  }
}
