import 'tablesorter';

/**
 * Ported from legacy asset pipeline reporting
 */

function initTableSorter() {
  // This prevents the tablesorter plugin to check for metadata which is done
  // using eval which conflicts with our csp.
  // Works because of a check in tablesorter:
  //  meta = $.metadata ? $header.metadata() : false;
  jQuery.metadata = undefined;

  // Override the default texts to enable translations
  jQuery.tablesorter.language = {
    sortAsc: I18n.t('js.sort.sorted_asc'),
    sortDesc: I18n.t('js.sort.sorted_dsc'),
    sortNone: I18n.t('js.sort.sorted_no'),
    sortDisabled: I18n.t('js.sort.sorting_disabled'),
    nextAsc: I18n.t('js.sort.activate_asc'),
    nextDesc: I18n.t('js.sort.activate_dsc'),
    nextNone: I18n.t('js.sort.activate_no'),
  };

  jQuery('#sortable-table')
    .not('.tablesorter')
    .tablesorter({
      sortList: [[0, 0]],
      widgets: ['saveSort'],
      widgetOptions: {
        storage_storageType: 's',
      },
      textExtraction(node:HTMLElement) {
        return node.getAttribute('raw-data');
      },
    });
}

export function registerTableSorter() {
  jQuery(document).ready(() => {
    initTableSorter();
  });

  jQuery(document).ajaxComplete(() => {
    initTableSorter();
  });
}
