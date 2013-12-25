timelinesApp.factory('Color', ['$http', 'APIUrlHelper', function($http, APIUrlHelper) {

  Color = function (data) {
     angular.extend(this, data);
  };

  Color.collectionFromResponse = function(response) {
    return response.data.colors.map(function(color){
      return new Color(color);
    });
  };

  Color.getCollection = function(params) {
    return $http({method: 'GET', url: APIUrlHelper.colorsPath(), params: params})
      .then(Color.collectionFromResponse);
  };

  // Color.buildFromResponse = function(response) {
  //   return new Color(response.data.color);
  // };

  // Color.getById = function(id) {
  //   return $http.get(APIUrlHelper.colorPath(id))
  //     .then(Color.buildFromResponse);
  // };

  return Color;
}]);
