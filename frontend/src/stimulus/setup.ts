import { Application } from '@hotwired/stimulus';
import { environment } from '../environments/environment';
import { OpApplicationController } from './controllers/op-application.controller';
import MainMenuController from './controllers/dynamic/menus/main.controller';
import OpDisableWhenCheckedController from './controllers/disable-when-checked.controller';
import PrintController from './controllers/print.controller';
import RefreshOnFormChangesController from './controllers/refresh-on-form-changes.controller';

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
