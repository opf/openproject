import { Application } from '@hotwired/stimulus';
import { environment } from '../environments/environment';
import { OpApplicationController } from './controllers/op-application.controller';
import MainMenuController from './controllers/dynamic/menus/main.controller';
import OpDisableWhenCheckedController from './controllers/disable-when-checked.controller';
import PrintController from './controllers/print.controller';
import RefreshOnFormChangesController from './controllers/refresh-on-form-changes.controller';
import AsyncDialogController from './controllers/async-dialog.controller';
import PollForChangesController from './controllers/poll-for-changes.controller';
import TableHighlightingController from './controllers/table-highlighting.controller';

declare global {
  interface Window {
    Stimulus:Application;
  }
}

const instance = Application.start();
window.Stimulus = instance;

instance.debug = !environment.production;
instance.handleError = (error, message, detail) => {
  console.warn(error, message, detail);
};

instance.register('application', OpApplicationController);
instance.register('menus--main', MainMenuController);

instance.register('disable-when-checked', OpDisableWhenCheckedController);
instance.register('print', PrintController);
instance.register('refresh-on-form-changes', RefreshOnFormChangesController);
instance.register('async-dialog', AsyncDialogController);
instance.register('poll-for-changes', PollForChangesController);
instance.register('table-highlighting', TableHighlightingController);
