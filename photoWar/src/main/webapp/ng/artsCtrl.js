totalApp.controller('artsCtrl', function ($scope, $http, $routeParams) {
    $scope.digest = unescape(decodeURIComponent(window.atob($routeParams.digest)));
    $scope.recs = [];
    $http.get('../listArts.jsp?d='+encodeURIComponent($scope.digest)).success( function(data) {
        $scope.recs = data;
    });
});
