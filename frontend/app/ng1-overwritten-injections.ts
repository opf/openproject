import {opServicesModule, opWorkPackagesModule} from 'core-app/angular-modules';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';

class Ng1WorkPackageCacheService extends WorkPackageCacheService {}
class Ng1SchemaCacheService extends SchemaCacheService {}
class Ng1WorkPackageTableRefreshService extends WorkPackageTableRefreshService {}

opWorkPackagesModule.service('wpCacheService', Ng1WorkPackageCacheService);
opWorkPackagesModule.service('schemaCacheService', Ng1SchemaCacheService);
opServicesModule.service('wpTableRefresh', Ng1WorkPackageTableRefreshService);
