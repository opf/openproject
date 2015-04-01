(function($) {
  $(function() {
    /*
     * @see /app/views/search/index.html.erb
     */
    if ($('#search-filter').length < 1) {
      return;
    }

    $('#search-input').focus();

  });
}(jQuery));
