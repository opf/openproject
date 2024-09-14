import {
  Component,
} from '@angular/core';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { RestrictedWpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import { WpTableConfigurationRelationSelectorComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration-relation-selector';
import { WpTableConfigurationModalPrependToken } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { ExternalQueryConfigurationComponent } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.component';

@Component({
  templateUrl: './external-query-configuration.template.html',
  providers: [
    [
      { provide: WpTableConfigurationService, useClass: RestrictedWpTableConfigurationService },
    ],
    { provide: WpTableConfigurationModalPrependToken, useValue: WpTableConfigurationRelationSelectorComponent },
  ],
})
export class ExternalRelationQueryConfigurationComponent extends ExternalQueryConfigurationComponent {
}
