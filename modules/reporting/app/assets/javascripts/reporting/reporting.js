//= require jquery-tablesorter

(function($){
  $(document).ajaxComplete(function() {
    // This prevents the tablesorter plugin to check for metadata which is done
    // using eval which conflicts with our csp.
    // Works because of a check in tablesorter:
    //  meta = $.metadata ? $header.metadata() : false;
    $.metadata = undefined;

    // Override the default texts to enable translations
    $.tablesorter.language = {
          sortAsc      : I18n.t('js.sort.sorted_asc'),
          sortDesc     : I18n.t('js.sort.sorted_dsc'),
          sortNone     : I18n.t('js.sort.sorted_no'),
          sortDisabled : I18n.t('js.sort.sorting_disabled'),
          nextAsc      : I18n.t('js.sort.activate_asc'),
          nextDesc     : I18n.t('js.sort.activate_dsc'),
          nextNone     : I18n.t('js.sort.activate_no')
    };

    $('#sortable-table')
      .not('.tablesorter')
      .tablesorter({
        sortList: [[0, 0]],
        textExtraction: function(node, table, cellIndex) {
          return $(node).attr('raw-data');
        }
      });
  });
})(jQuery);
