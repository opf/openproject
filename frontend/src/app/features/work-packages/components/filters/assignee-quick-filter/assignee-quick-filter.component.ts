import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostListener,
  OnInit,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { firstValueFrom } from 'rxjs';
import { take } from 'rxjs/operators';

const MAGIC_PAGE_SIZE = 500;

@Component({
  selector: 'op-assignee-quick-filter',
  templateUrl: './assignee-quick-filter.component.html',
  styleUrls: ['./assignee-quick-filter.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class AssigneeQuickFilterComponent extends UntilDestroyedMixin implements OnInit {
  public isOpen = false;

  public members:HalResource[] = [];

  public membersLoading = false;

  /** Hrefs of currently selected users (= operator) */
  public selectedHrefs = new Set<string>();

  /** Whether the "Não atribuído" (!* operator) option is selected */
  public unassignedSelected = false;

  private currentUserId:string|null = null;

  public readonly meValue:HalResource = this.halResourceService.createHalResource({
    _links: {
      self: {
        href: this.apiV3Service.users.me.path,
        title: this.I18n.t('js.label_me'),
      },
    },
  }, true);

  readonly text = {
    assignee: 'Responsável',
    me: this.I18n.t('js.label_me'),
    unassigned: 'Não atribuído',
    clearFilter: 'Limpar filtro',
    loading: '...',
  };

  constructor(
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly halResourceService:HalResourceService,
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly currentUserService:CurrentUserService,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
  ) {
    super();
  }

  ngOnInit():void {
    this.currentUserService.user$
      .pipe(take(1), this.untilDestroyed())
      .subscribe((user) => {
        this.currentUserId = user.id;
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
    return this.selectedHrefs.size > 0 || this.unassignedSelected;
  }

  public get label():string {
    if (!this.isActive) return this.text.assignee;
    if (this.unassignedSelected) return this.text.unassigned;
    if (this.selectedHrefs.size === 1) {
      const href = Array.from(this.selectedHrefs)[0];
      if (href === this.apiV3Service.users.me.path) return this.text.me;
      const found = this.members.find((m) => m.href === href);
      return found ? (found.name as string || this.text.assignee) : this.text.assignee;
    }
    return `${this.text.assignee} (${this.selectedHrefs.size})`;
  }

  public isSelected(member:HalResource):boolean {
    return this.selectedHrefs.has(member.href!);
  }

  public initials(member:HalResource):string {
    const name = (member.name || '') as string;
    return name.split(' ').slice(0, 2).map((w:string) => w[0]).join('').toUpperCase();
  }

  public toggleDropdown(event:MouseEvent):void {
    event.stopPropagation();
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  public toggleMember(member:HalResource):void {
    this.unassignedSelected = false;
    const href = member.href!;
    if (this.selectedHrefs.has(href)) {
      this.selectedHrefs.delete(href);
    } else {
      this.selectedHrefs.add(href);
    }
    this.applyFilter();
    this.cdRef.detectChanges();
  }

  public toggleUnassigned():void {
    this.selectedHrefs.clear();
    this.unassignedSelected = !this.unassignedSelected;
    this.applyFilter();
    this.cdRef.detectChanges();
  }

  public clearAll():void {
    this.selectedHrefs.clear();
    this.unassignedSelected = false;
    this.wpTableFilters.remove('responsible');
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
    if (this.members.length === 0) {
      void this.loadMembers();
    }
    this.cdRef.detectChanges();
  }

  private close():void {
    this.isOpen = false;
    this.cdRef.detectChanges();
  }

  private async loadMembers():Promise<void> {
    this.membersLoading = true;
    this.cdRef.detectChanges();

    try {
      const href = this.getAllowedValuesHref();
      if (!href) return;

      const collection = await firstValueFrom(
        (this.apiV3Service.collectionFromString(href) as ApiV3ResourceCollection<HalResource, ApiV3Resource>)
          .filtered(new ApiV3FilterBuilder(), { pageSize: `${MAGIC_PAGE_SIZE}` })
          .get(),
      ) as CollectionResource;

      const mePath = this.apiV3Service.users.me.path;
      const currentUserPath = this.currentUserId ? `/api/v3/users/${this.currentUserId}` : null;

      this.members = (collection.elements as HalResource[]).filter((m) => {
        if (m.href === mePath) return false;
        if (currentUserPath && m.href === currentUserPath) return false;
        return true;
      });
    } catch {
      this.members = [];
    } finally {
      this.membersLoading = false;
      this.cdRef.detectChanges();
    }
  }

  private getAllowedValuesHref():string|null {
    try {
      const filter = this.wpTableFilters.instantiate('responsible');
      const allowedValues = filter.currentSchema?.values?.allowedValues as { href?:string }|undefined;
      return allowedValues?.href || null;
    } catch {
      return null;
    }
  }

  private applyFilter():void {
    if (!this.isActive) {
      this.wpTableFilters.remove('responsible');
      return;
    }

    if (this.unassignedSelected) {
      this.wpTableFilters.replace('responsible', (filter:QueryFilterInstanceResource) => {
        filter.operator = filter.findOperator('!*')!;
        filter.values = [];
      });
      return;
    }

    const values:HalResource[] = Array.from(this.selectedHrefs).map((href) => {
      if (href === this.apiV3Service.users.me.path) return this.meValue;
      return this.members.find((m) => m.href === href) || this.halResourceService.createHalResource({
        _links: { self: { href } },
      }, true);
    });

    this.wpTableFilters.replace('responsible', (filter:QueryFilterInstanceResource) => {
      filter.operator = filter.findOperator('=')!;
      filter.values = values;
    });
  }

  private syncFromFilter():void {
    const filter = this.wpTableFilters.find('responsible');
    this.selectedHrefs.clear();
    this.unassignedSelected = false;

    if (!filter) return;

    if (filter.operator?.id === '!*') {
      this.unassignedSelected = true;
      return;
    }

    (filter.values as HalResource[]).forEach((v) => {
      if (v.href) this.selectedHrefs.add(v.href);
    });
  }
}
