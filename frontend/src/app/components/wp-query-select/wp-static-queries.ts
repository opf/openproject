
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';

export class WorkPackageStaticQueries {


  public static get all() {
    let latestActivityQuery = { category: null, query: null, label: 'Latest Activity', query_props: '%5B%7B%22project_identifier%22%3A%7B%22operator%22%3A%22%3D%22%2C%22values%22%3A%5B%22demo-project%22%5D%7D%7D%5D'};
    let ganttQuery = { category: null, query: null, label: 'Gantt Chart', query_props: '%7B%22tv%22%3Atrue%7D' };
    let createdByMeQuery = { category: null, query: null, label: 'Created by me', query_props: '%5B%7B%22project_identifier%22%3A%7B%22operator%22%3A%22%3D%22%2C%22values%22%3A%5B%22demo-project%22%5D%7D%7D%5D' };
    let assignedToMeQuery = { category: null, query: null, label: 'Assigned to me', query_props: '%5B%7B%22status%22%3A%7B%22operator%22%3A%22o%22%2C%22values%22%3A%5B%5D%7D%7D%2C%7B%22author%22%3A%7B%22operator%22%3A%22%3D%22%2C%22values%22%3A%5B%22me%22%5D%7D%7D%5D' };
    let recentlyCreatedQuery = { category: null, query: null, label: 'Recently created', query_props: '%5B%7B%22project_identifier%22%3A%7B%22operator%22%3A%22%3D%22%2C%22values%22%3A%5B%22demo-project%22%5D%7D%7D%5D' };
    let defaultQuery = { category: null, query: null, label: 'All open', query_props: '' };

    return [latestActivityQuery, ganttQuery, createdByMeQuery, assignedToMeQuery, recentlyCreatedQuery, defaultQuery];
  }

  public static nameFor(query:QueryResource) {
    let filters:string[] = [];
    _.each(query.filters, filter => {
      filters.push(filter.name);
    });

    if (filters.includes('Author')) {

    } else if (filters.includes('Assignee')) {

    } else if (filters.includes('Created')) {

    }

    return 'All open';
  }
}
