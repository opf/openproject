import {opServicesModule, opWorkPackagesModule} from 'core-app/angular-modules';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {ExternalQueryConfigurationService} from "core-components/wp-table/external-configuration/external-query-configuration.service";

class Ng1WorkPackageCacheService extends WorkPackageCacheService {
}

class Ng1SchemaCacheService extends SchemaCacheService {
}

class Ng1WorkPackageTableRefreshService extends WorkPackageTableRefreshService {
}

class Ng1ExternalQueryConfigurationService extends ExternalQueryConfigurationService {
}

opWorkPackagesModule.service('wpCacheService', Ng1WorkPackageCacheService);
opWorkPackagesModule.service('schemaCacheService', Ng1SchemaCacheService);
opServicesModule.service('wpTableRefresh', Ng1WorkPackageTableRefreshService);
opServicesModule.service('externalQueryConfiguration', Ng1ExternalQueryConfigurationService);
