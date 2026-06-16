import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostListener,
  Input,
  OnInit,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { firstValueFrom } from 'rxjs';
import { skip, take } from 'rxjs/operators';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import {
  ITypeQuickFilterView,
} from 'core-app/features/user-preferences/state/user-preferences.model';
import {
  TypeQuickFilterStateService,
} from 'core-app/features/work-packages/components/filters/type-quick-filter/type-quick-filter-state.service';

const MAGIC_PAGE_SIZE = 500;

@Component({
  selector: 'op-type-quick-filter',
  templateUrl: './type-quick-filter.component.html',
  styleUrls: ['./type-quick-filter.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class TypeQuickFilterComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public viewKey:ITypeQuickFilterView = 'work_packages';

  public isOpen = false;

  public types:HalResource[] = [];

  public typesLoading = false;

  public selectedHrefs = new Set<string>();

  private currentUserId:string|null = null;

  readonly text = {
    type: 'Tipo',
    clearFilter: 'Mostrar todos',
    loading: '...',
  };

  constructor(
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly currentUserService:CurrentUserService,
    readonly userPreferencesService:UserPreferencesService,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly typeQuickFilterState:TypeQuickFilterStateService,
  ) {
    super();
  }

  ngOnInit():void {
    this.currentUserService.user$
      .pipe(take(1), this.untilDestroyed())
      .subscribe((user) => {
        this.currentUserId = user.id;
        if (user.id) {
          this.userPreferencesService.get(user.id);
          // skip(1) skips the initial default state; wait for the API response
          this.userPreferencesService.query.preferences$
            .pipe(skip(1), take(1), this.untilDestroyed())
            .subscribe((prefs) => {
              const savedHrefs = prefs.typeQuickFilter?.[this.viewKey];
              if (savedHrefs && savedHrefs.length > 0) {
                savedHrefs.forEach((href) => this.selectedHrefs.add(href));
                this.applyFilter();
                void this.loadTypes().then(() => { this.cdRef.detectChanges(); });
              }
            });
        }
      });

    this.wpTableFilters
      .pristine$()
      .pipe(this.untilDestroyed())
      .subscribe(() => {
        this.syncFromFilter();
        this.cdRef.detectChanges();
      });
  }

  public get isActive():boolean {
    return this.selectedHrefs.size > 0;
  }

  public get label():string {
    if (!this.isActive) return this.text.type;
    if (this.selectedHrefs.size === 1) {
      const href = Array.from(this.selectedHrefs)[0];
      const found = this.types.find((t) => t.href === href);
      return found ? (found?.name != null ? found.name as string : this.text.type) : this.text.type;
    }
    return `${this.text.type} (${this.selectedHrefs.size})`;
  }

  public isSelected(type:HalResource):boolean {
    return this.selectedHrefs.has(type.href!);
  }

  public toggleDropdown(event:MouseEvent):void {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  public toggleType(type:HalResource):void {
    const href = type.href!;
    if (this.selectedHrefs.has(href)) {
      this.selectedHrefs.delete(href);
    } else {
      this.selectedHrefs.add(href);
    }
    this.applyFilter();
    this.savePreference();
    this.close();
  }

  public clearAll():void {
    this.selectedHrefs.clear();
    this.typeQuickFilterState.update(new Set());
    this.savePreference();
    this.close();
  }

  @HostListener('document:click', ['$event'])
  public onDocumentClick(event:MouseEvent):void {
    if (this.isOpen && !this.elementRef.nativeElement.contains(event.target)) {
      this.close();
    }
  }

  private open():void {
    this.isOpen = true;
    if (this.types.length === 0) {
      void this.loadTypes();
    }
    this.cdRef.detectChanges();
  }

  private close():void {
    this.isOpen = false;
    this.cdRef.detectChanges();
  }

  private async loadTypes():Promise<void> {
    this.typesLoading = true;
    this.cdRef.detectChanges();

    try {
      const href = this.getAllowedValuesHref();
      if (!href) return;

      const collection = await firstValueFrom(
        (this.apiV3Service.collectionFromString(href) as ApiV3ResourceCollection<HalResource, ApiV3Resource>)
          .filtered(new ApiV3FilterBuilder(), { pageSize: `${MAGIC_PAGE_SIZE}` })
          .get(),
      ) as CollectionResource;

      this.types = collection.elements as HalResource[];
    } catch {
      this.types = [];
    } finally {
      this.typesLoading = false;
      this.cdRef.detectChanges();
    }
  }

  private getAllowedValuesHref():string|null {
    try {
      const filter = this.wpTableFilters.instantiate('type');
      const allowedValues = filter.currentSchema?.values?.allowedValues as { href?:string }|undefined;
      return allowedValues?.href || null;
    } catch {
      return null;
    }
  }

  private applyFilter():void {
    // Client-side only: hierarchy builder reads this state to hide root-level non-matching WPs.
    // No API-level type_id filter — preserves descendants of matching roots in the result set.
    this.typeQuickFilterState.update(new Set(this.selectedHrefs));
  }

  private syncFromFilter():void {
    // No API filter to sync from — state is owned by this component and user preferences.
    this.typeQuickFilterState.update(new Set(this.selectedHrefs));
  }

  private savePreference():void {
    if (!this.currentUserId) return;
    const hrefs = Array.from(this.selectedHrefs);
    void firstValueFrom(this.userPreferencesService.query.preferences$).then((prefs) => {
      this.userPreferencesService.update(this.currentUserId!, {
        typeQuickFilter: {
          ...(prefs.typeQuickFilter ?? {}),
          [this.viewKey]: hrefs.length > 0 ? hrefs : null,
        },
      });
    });
  }
}
