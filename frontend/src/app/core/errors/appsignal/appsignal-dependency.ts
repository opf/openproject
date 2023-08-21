import Appsignal from '@appsignal/javascript';
import { Span } from '@appsignal/javascript/dist/esm/span';
import { plugin as networkPlugin } from '@appsignal/plugin-breadcrumbs-network';

export {
  Appsignal,
  Span,
  networkPlugin,
};
