import { Controller } from '@hotwired/stimulus';

import './reporting/reporting_engine';
import './reporting/reporting_engine/filters';
import './reporting/reporting_engine/group_bys';
import './reporting/reporting_engine/restore_query';
import './reporting/reporting_engine/controls';
import { registerTableSorter } from './reporting/tablesorter';

export default class BacklogsController extends Controller {
  connect() {
    super.connect();

    // Register table sorting functionality after reporting engine loaded
    registerTableSorter();
  }
}
