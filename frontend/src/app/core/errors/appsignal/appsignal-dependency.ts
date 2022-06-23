import Appsignal from '@appsignal/javascript';
import { Span } from '@appsignal/javascript/dist/esm/span';
import { plugin as networkPlugin } from '@appsignal/plugin-breadcrumbs-network';
import { plugin as consolePlugin } from '@appsignal/plugin-breadcrumbs-console';

export {
  Appsignal,
  Span,
  networkPlugin,
  consolePlugin,
};
