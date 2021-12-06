import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  ViewChild,
} from '@angular/core';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  catchError,
  map,
} from 'rxjs/operators';
import {
  Observable,
  of,
} from 'rxjs';
import { IsolatedQuerySpace } from '../../directives/query-space/isolated-query-space';
import { WorkPackageNotificationService } from '../../services/notifications/work-package-notification.service';
import { UrlParamsHelperService } from '../wp-query/url-params-helper';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

@Component({
  templateUrl: './op-wp-quick-add-modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OPWPQuickAddModalComponent extends OpModalComponent {
  selectedWorkPackage?:WorkPackageResource;

  readonly text = {
    placeholder: this.I18n.t('js.relations_autocomplete.placeholder'),
    title: this.I18n.t('js.modals.quick_add.title'),
    close: this.I18n.t('js.button_close'),
    add: this.I18n.t('js.button_add'),
  };

  constructor(readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly apiV3Service:APIV3Service,
    readonly querySpace:IsolatedQuerySpace,
    private readonly notificationService:WorkPackageNotificationService,
    private readonly urlParamsHelper:UrlParamsHelperService,
    private readonly schemaCacheService:SchemaCacheService,
    private readonly CurrentProject:CurrentProjectService) {
    super(locals, cdRef, elementRef);
  }

  @ViewChild(OpAutocompleterComponent) public ngSelectComponent:OpAutocompleterComponent;

  fetchAutocompleterData = (searchString:string):Observable<WorkPackageResource[]> => {
    if (searchString.length === 0) {
      return of([]);
    }
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    const results = this.querySpace.results.value;
    const query = this.querySpace.query.value;
    filters.add('subjectOrId', '**', [searchString]);

    if (results && results.elements.length > 0) {
      filters.add('id', '!', results.elements.map((wp:WorkPackageResource) => wp.id || ''));
    }
    if (query?.filters) {
      const currentFilters = this.urlParamsHelper.buildV3GetFilters(query.filters);
      filters.merge(currentFilters, 'subprojectId');
    }
    return this
      .apiV3Service
      .withOptionalProject(this.CurrentProject.id)
      .work_packages
      .filtered(filters)
      .get()
      .pipe(
        map((collection) => collection.elements),
        catchError((error:unknown) => {
          this.notificationService.handleRawError(error);
          return of([]);
        }),
      );
  };

  public autocompleterOptions = {
    resource: 'work_packages',
    getOptionsFn: this.fetchAutocompleterData,
  };

  public onSubmit(evt:Event):void {
    evt.preventDefault();

    if (!this.selectedWorkPackage) {
      return;
    }

    void this.schemaCacheService
      .ensureLoaded(this.selectedWorkPackage)
      .then(() => {
        // we should handle what to do after selecting the wp
        this.ngSelectComponent.closeSelect();
        this.closeMe();
      });
  }
}
