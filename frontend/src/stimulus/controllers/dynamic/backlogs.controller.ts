import { Controller } from '@hotwired/stimulus';

require('core-vendor/jquery.flot/jquery.flot');
require('core-vendor/jquery.flot/excanvas');
require('core-vendor/jquery.jeditable.mini');
require('core-vendor/jquery.cookie');
require('core-vendor/jquery.colorcontrast');

require('./backlogs/common');
require('./backlogs/master_backlog');
require('./backlogs/backlog');
require('./backlogs/burndown');
require('./backlogs/model');
require('./backlogs/editable_inplace');
require('./backlogs/sprint');
require('./backlogs/work_package');
require('./backlogs/story');
require('./backlogs/task');
require('./backlogs/impediment');
require('./backlogs/taskboard');
require('./backlogs/show_main');

export default class BacklogsController extends Controller {
}
