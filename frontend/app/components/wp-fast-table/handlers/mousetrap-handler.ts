import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../wp-fast-table';
import {WorkPackageTableSelection} from '../state/wp-table-selection.service';

export class MousetrapHandler {
  public wpTableSelection:WorkPackageTableSelection;

  constructor() {
    injectorBridge(this);
  }

  public attachTo(table: WorkPackageTable) {

    // Bind CTRL+A to select all work packages
    Mousetrap.bind(['command+a', 'ctrl+a'], (e) => {
      this.wpTableSelection.selectAll(table.rows);

      e.preventDefault();
      return false;
    });

    // Bind CTRL+D to deselect all work packages
    Mousetrap.bind(['command+d', 'ctrl+d'], (e) => {
      this.wpTableSelection.reset();
      e.preventDefault();
      return false;
    });

  }
}

MousetrapHandler.$inject = ['wpTableSelection'];
