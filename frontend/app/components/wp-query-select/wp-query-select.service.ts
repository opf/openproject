import {WorkPackageQuerySelectController} from './wp-query-select.controller'
import {opWorkPackagesModule} from '../../angular-modules';

function wpQuerySelect(ngContextMenu:any) {

  return ngContextMenu({
    templateUrl: '/components/wp-query-select/wp-query-select.template.html',
    container: '.title-container',
    controller: WorkPackageQuerySelectController
  });
}

opWorkPackagesModule.factory('wpQuerySelectService', wpQuerySelect);
