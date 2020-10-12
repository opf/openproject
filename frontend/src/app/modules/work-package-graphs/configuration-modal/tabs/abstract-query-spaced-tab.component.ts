import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {WpGraphConfigurationService} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration.service";

export abstract class QuerySpacedTabComponent {
  constructor(readonly I18n:I18nService,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly wpGraphConfiguration:WpGraphConfigurationService) {
  }

  protected initializeQuerySpace() {
    return this
             .wpGraphConfiguration
             .formFor(this.query)
             .then(form => {
               this.wpStatesInitialization.initialize(this.query, this.query.results);
               this.wpStatesInitialization.updateStatesFromForm(this.query, form);
             });
  }

  protected abstract get query():QueryResource;
}
