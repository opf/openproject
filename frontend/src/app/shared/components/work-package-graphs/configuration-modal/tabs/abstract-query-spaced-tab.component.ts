import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';

export abstract class QuerySpacedTabComponent {
  constructor(readonly I18n:I18nService,
    readonly wpStatesInitialization:WorkPackageStatesInitializationService,
    readonly wpGraphConfiguration:WpGraphConfigurationService) {
  }

  protected initializeQuerySpace() {
    return this
      .wpGraphConfiguration
      .formFor(this.query)
      .then((form) => {
        this.wpStatesInitialization.initialize(this.query, this.query.results);
        this.wpStatesInitialization.updateStatesFromForm(this.query, form);
      });
  }

  protected abstract get query():QueryResource;
}
