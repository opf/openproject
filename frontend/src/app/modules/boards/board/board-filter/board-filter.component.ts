import {AfterViewInit, Component, Input} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {QueryFormDmService} from "core-app/modules/hal/dm-services/query-form-dm.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {StateService} from "@uirouter/core";
import {debounceTime, skip, take} from "rxjs/internal/operators";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {Observable} from "rxjs";
import {BoardFiltersService} from "core-app/modules/boards/board/board-filter/board-filters.service";

@Component({
  selector: 'board-filter',
  templateUrl: './board-filter.component.html'
})
export class BoardFilterComponent extends UntilDestroyedMixin implements AfterViewInit {
  /** Current active */
  @Input() public board$:Observable<Board>;

  initialized = false;

  constructor(private readonly currentProjectService:CurrentProjectService,
              private readonly querySpace:IsolatedQuerySpace,
              private readonly halResourceService:HalResourceService,
              private readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              private readonly wpTableFilters:WorkPackageViewFiltersService,
              private readonly urlParamsHelper:UrlParamsHelperService,
              private readonly boardFilters:BoardFiltersService,
              private readonly $state:StateService,
              private readonly queryFormDm:QueryFormDmService) {
    super();
  }

  ngAfterViewInit():void {
    if (!this.board$) {
      return;
    }

    this.board$
      .pipe(take(1))
      .subscribe(board => {
        // Initially load the form once to be able to render filters
        this.loadQueryForm();

        // Update checksum service whenever filters change
        this.updateChecksumOnFilterChanges();

        // Remove action attribute from filter service
        if (board.isAction) {
          this.wpTableFilters.hidden.push(board.actionAttribute!);
        }
      });
  }

  private updateChecksumOnFilterChanges() {
    this.wpTableFilters
      .live$()
      .pipe(
        this.untilDestroyed(),
        skip(1),
        debounceTime(250)
      )
      .subscribe(() => {

        const filters:QueryFilterInstanceResource[] = this.wpTableFilters.current;
        let filterHash = this.urlParamsHelper.buildV3GetFilters(filters);
        let query_props = JSON.stringify(filterHash);

        this.boardFilters.filters.putValue(filterHash);

        this.$state.go('.', { query_props: query_props }, { custom: { notify: false } });
      });
  }

  private loadQueryForm() {
    this.queryFormDm
      .loadWithParams(
        { filters: JSON.stringify(this.boardFilters.current) },
        undefined,
        this.currentProjectService.id
      )
      .then((form:QueryFormResource) => {
        const query:QueryResource = this.halResourceService.createHalResourceOfClass(
          QueryResource,
          form.payload.$source
        );

        this.querySpace.query.putValue(query);
        this.wpStatesInitialization.updateStatesFromForm(query, form);
      });
  }
}
