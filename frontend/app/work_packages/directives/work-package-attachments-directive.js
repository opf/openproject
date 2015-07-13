module.exports = function(Upload) {

  var attachmentsController = function(scope) {

    scope.remove = function(file) {
      _.remove(scope.files, function(element) {
        return file === element;
      })
    }

    scope.removeAll = function() {
      scope.files = []
    }

  }

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/attachments.html',
    link: attachmentsController
  }
}
