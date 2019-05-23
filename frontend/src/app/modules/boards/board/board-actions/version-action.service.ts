import {Injectable} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {Board} from "core-app/modules/boards/board/board";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {VersionResource} from "core-app/modules/hal/resources/version-resource";
import {VersionDmService} from "core-app/modules/hal/dm-services/version-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

@Injectable()
export class BoardVersionActionService implements BoardActionService {

  constructor(protected boardListsService:BoardListsService,
              protected I18n:I18nService,
              protected versionDm:VersionDmService,
              protected currentProject:CurrentProjectService,
              protected pathHelper:PathHelperService) {
  }

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.version');
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns /api/v3/versions/:id if a version filter exists
   */
  public getFilterValue(query:QueryResource):string|undefined {
    const filter = _.find(query.filters, filter => filter.id === 'version');

    if (filter) {
      const value = filter.values[0] as string|HalResource;
      return (value instanceof HalResource) ? value.href! : value;
    }

    return;
  }

  public addActionQueries(board:Board):Promise<Board> {
    return this.getVersions()
      .then((results) => {
        return Promise.all<unknown>(
          results.map((version:VersionResource) => {
            if (version.definingProject.name === this.currentProject.name) {
              return this.addActionQuery(board, version);
            }

            return Promise.resolve(board);
          })
        )
          .then(() => board);
      });
  }

  public addActionQuery(board:Board, value:HalResource):Promise<Board> {
    let params:any = {
      name: value.name,
    };

    let filter = { version: {
      operator: '=' as FilterOperator,
      values: [value.id]
    }};

    return this.boardListsService.addQuery(board, params, [filter]);
  }

  /**
   * Return available versions for new lists, given the list of active
   * queries in the board.
   *
   * @param board The board we're looking at
   * @param queries The active set of queries
   */
  public getAvailableValues(board:Board, queries:QueryResource[]):Promise<HalResource[]> {
    const active = new Set(
      queries.map(query => this.getFilterValue(query))
    );

    return this.getVersions()
      .then(results =>
        results.filter(version => !active.has(version.href!))
      );
  }

  /**
   * Checks for correct permissions
   * (whether the current project is in the list of allowed values in the version create form)
   * @returns {Promise<boolean>}
   */
  public canCreateNewActionElements():Promise<boolean> {
    let that = this;
    return this.versionDm.listProjectsAvailableForVersions().then((collection) => {
      return collection.elements.some((e:HalResource) => e.id === that.currentProject.id!);
    }).catch(() => {
      return false;
    });
  }

  /**
   * Creates a new version with the given name
   * @param {string} the name of the new version
   * @returns {Promise<HalResource | void>}
   */
  public createNewActionElement(name:string):Promise<HalResource|void> {
    return this.versionDm.createVersion(this.getVersionPayload(name));
  }

  /**
   * Adds an entry to the list menu to edit the version if allowed
   * @param {HalResource} actionAttributeValue
   * @returns {Promise<any>}
   */
  public getAdditionalListMenuItems(actionAttributeValue:HalResource):Promise<any> {
    let items:any = [];
    const actionID = actionAttributeValue.id;

    if (actionID) {
      return this.versionDm.one(parseInt(actionID)).then((version) => {
        // Show entry only with correct permissions
        if (version.$links.update) {
          items.push(
            {
              linkText: this.I18n.t('js.boards.lists.edit_version'),
              externalAction: () => window.open(this.pathHelper.versionEditPath(actionID), '_blank')
            }
          );
        }

        return items;
      });
    } else {
      return Promise.resolve(items);
    }
  }

  private getVersions():Promise<VersionResource[]> {
    if (this.currentProject.id === null) {
      return Promise.resolve([]);
    }

    return this.versionDm
      .listForProject(this.currentProject.id)
      .then(collection => collection.elements.filter(version => version.status === 'open'));
  }

  private getVersionPayload(name:string) {
    let payload:any = {};
    payload['name'] = name;
    payload['_links'] = {
      definingProject: {
        href: this.pathHelper.api.v3.projects.id(this.currentProject.id!).path
      }
    };

    return payload;
  }
}
