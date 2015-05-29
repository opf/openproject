!(function($) {
  var watchButtons = $('.button[data-unwatch-text]');
  watchButtons.each(function updateTextAndIcon(_, el) {
    var button = $(el),
        text = button.data('unwatch-text'),
        icon = button.data('unwatch-icon'),
        oldIcon = button.data('watch-icon'),
        path = button.data('unwatch-path'),
        method = button.data('unwatch-method');

    button.find('span.button--text').text(text);
    button.find('i.button--icon').removeClass('icon-' + oldIcon).addClass('icon-' + icon);
    button.attr('href', path).data('method', method);
  });
}(jQuery));
