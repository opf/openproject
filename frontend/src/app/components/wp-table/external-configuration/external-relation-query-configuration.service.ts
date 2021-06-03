import { Injectable } from '@angular/core';
import {
  Class,
  ExternalQueryConfigurationService
} from "core-components/wp-table/external-configuration/external-query-configuration.service";
import { ExternalRelationQueryConfigurationComponent } from "core-components/wp-table/external-configuration/external-relation-query-configuration.component";

@Injectable()
export class ExternalRelationQueryConfigurationService extends ExternalQueryConfigurationService {
  externalQueryConfigurationComponent():Class {
    return ExternalRelationQueryConfigurationComponent;
  }
}
