//= require jquery-tablesorter

(function($){

  $(document).ajaxComplete(function() {
    $('#sortable-table').not('.tablesorter').tablesorter();
  });
})(jQuery);
