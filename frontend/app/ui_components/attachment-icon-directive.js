module.exports = function() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      type: '&'
    },
    template: '<i class="icon-{{icon}}"></i>',
    link: function(scope) {
      var icon, type = scope.type();
      switch(type) {
        // images
        case 'image/png':
        case 'image/jpg':
        case 'image/gif':
          icon = 'image1'
          break;
        // documents
        case 'application/pdf':
          icon = 'page-pdf';
          break;
        case 'application/excel':
        case 'application/vnd.ms-excel':
        case 'application/x-excel':
        case 'application/x-msexcel':
          icon = 'page-xls';
          break;
        default:
          icon = 'ticket';
          break;
      }

      scope.icon = icon;
    }
  }
}
