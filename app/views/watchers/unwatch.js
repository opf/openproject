!(function($) {
  var watchButtons = $('.button[data-watch-text]');
  watchButtons.each(function updateTextAndIcon(_, el) {
    var button = $(el),
        text = button.data('watch-text'),
        icon = button.data('watch-icon'),
        oldIcon = button.data('unwatch-icon'),
        path = button.data('watch-path'),
        method = button.data('watch-method');

    button.find('span.button--text').text(text);
    button.find('i.button--icon').removeClass('icon-' + oldIcon).addClass('icon-' + icon);
    button.attr('href', path).data('method', method)
  });
}(jQuery));
