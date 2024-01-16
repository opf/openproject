import { I18nService } from 'core-app/core/i18n/i18n.service';
import { StateService } from '@uirouter/angular';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { WpTableWithGanttConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-with-gantt-configuration.service';

export const WorkPackageTableConfigurationFactory = (i18n:I18nService, $state:StateService) => {
  // in the WP module we want the default table configuration options
  if ($state.current.name?.includes('work-packages')) {
    return new WpTableConfigurationService(i18n);
  }

  // In all others we want the Gantt option as well
  return new WpTableWithGanttConfigurationService(i18n);
};
