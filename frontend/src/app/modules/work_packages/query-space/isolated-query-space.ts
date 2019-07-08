import {RenderedRow} from 'app/components/wp-fast-table/builders/primary-render-pass';
import {derive, input, InputState, State, StatesGroup} from 'reactivestates';
import {Subject} from 'rxjs';
import {Injectable} from '@angular/core';
import {map} from 'rxjs/operators';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {GroupObject, WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {WPFocusState} from "core-components/wp-fast-table/state/wp-table-focus.service";
import {QueryColumn} from "core-components/wp-query/query-column";
import {WorkPackageTableRefreshRequest} from "core-components/wp-table/wp-table-refresh-request.service";

@Injectable()
export class IsolatedQuerySpace extends StatesGroup {

  constructor() {
    super();
  }

  name = 'IsolatedQuerySpace';

  // The query that results in this table state
  query:InputState<QueryResource> = input<QueryResource>();

  // the query form associated with the table
  queryForm = input<QueryFormResource>();

  // the results associated with the table
  results = input<WorkPackageCollectionResource>();
  // all groups returned as results
  groups = input<GroupObject[]>();
  // Set of columns in strict order of appearance
  columns = input<QueryColumn[]>();

  // Current state of collapsed groups (if any)
  collapsedGroups = input<{ [identifier:string]:boolean }>();
  // State to be updated when the table is up to date
  rendered = input<RenderedRow[]>();

  renderedWorkPackages:State<RenderedRow[]> = derive(this.rendered, $ => $.pipe(
    map(rows => rows.filter(row => !!row.workPackageId)))
  );

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage:InputState<WPFocusState> = input<WPFocusState>();

  // Subject used to unregister all listeners of states above.
  stopAllSubscriptions = new Subject();
  // Fire when table refresh is required
  refreshRequired = input<WorkPackageTableRefreshRequest>();

  // Required work packages to be rendered by hierarchy mode + relation columns
  additionalRequiredWorkPackages = input<null>();

  // Input state that emits whenever table services have initialized
  initialized = input<unknown>();
}
