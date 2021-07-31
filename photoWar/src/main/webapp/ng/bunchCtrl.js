    totalApp.controller('bunchCtrl', function ($scope, $http, bunchFactory, $timeout) {
        $scope.showTop = false;
        $scope.pageSize = 20;
        $scope.colTrim = 120;
        $scope.recs = new Array();
        $scope.rereadData = function() {
            bunchFactory.list( function(data) {
                $scope.recs = data;
            });
            $timeout( $scope.rereadData, 60000 );
        }
        $scope.rereadData();
        $scope.filteredRecs = $scope.recs;
        $scope.filterVal = "";
        $scope.sort = "digest";
        $scope.offset = 0;
        $scope.search = "";
        $scope.showId = false;
        $scope.nextPage = function() {
            if ($scope.offset < $scope.recs.length-$scope.pageSize) {
                $scope.offset+=$scope.pageSize;
            }
            else {
                $scope.offset=$scope.recs.length-$scope.pageSize;
            }
            $scope.pickNewSearchValue();
        };
        $scope.prevPage = function() {
            if ($scope.offset > $scope.pageSize) {
                $scope.offset-=$scope.pageSize;
            }
            else {
                $scope.offset=0;
            }
            $scope.pickNewSearchValue();
        };
        $scope.$watch('filterVal', function(newVal, oldVal) {
            if (newVal) {
                $scope.findSearchValueOffset();
            }
        });
        $scope.pickNewSearchValue = function() {
            console.log("pickNewSearchValue");
            if ($scope.filteredRecs.length<$scope.filteredRecs.length) {
                $scope.offset = 0;
            }
            if ($scope.offset > $scope.filteredRecs.length) {
                $scope.offset = $scope.filteredRecs.length - $scope.pageSize;
            }
            if ($scope.offset < 0) {
                $scope.offset = 0;
            }
            if ($scope.offset > $scope.filteredRecs.length-4) {
                $scope.search = $scope.filteredRecs[$scope.filteredRecs.length-1].digest;
            }
            else {
                $scope.search = $scope.filteredRecs[$scope.offset+4].digest;
            }
        }
        $scope.firstPage = function() {
            $scope.offset=0;
            $scope.pickNewSearchValue();
        };
        $scope.lastPage = function() {
            $scope.offset= $scope.filteredRecs.length - $scope.pageSize;
            if ($scope.offset<0) {
                $scope.offset = 0;
            }
            $scope.pickNewSearchValue();
        };
        $scope.sortDigest = function() {
            $scope.sort = "digest";
            $scope.findSearchValueOffset();
        }
        $scope.sortSize = function() {
            $scope.sort = "size";
            $scope.findSearchValueOffset();
        }
        $scope.findSearchValueOffset = function() {
            console.log("findSearchValueOffset");
            $scope.calcFiltered();
            var dispArray = $scope.filteredRecs;
            var length = dispArray.length;
            var best = "";
            var newOffset = -1;
            var altOffset = -1;
            for(var j = 0; j < length; j++) {
                var rec = dispArray[j];
                var dig = rec.digest;
                if (dig == $scope.search) {
                    newOffset = j;
                }
                else if (dig < $scope.search) {
                    if (dig > best) {
                        best = dig;
                        altOffset = j;
                    }
                }
            }
            if (newOffset < 0) {
                newOffset = altOffset;
                $scope.search = best;
            }
            if (newOffset<4) {
                $scope.offset = 0;
            }
            else {
                $scope.offset = newOffset - 4;
            }
        }
        $scope.calcFiltered = function() {
            console.log("calcFiltered");
            if ($scope.sort == "digest") {
                $scope.recs.sort( function(a, b){
                    return ( a.digest > b.digest ) ? 1 : -1;
                });
            }
            else if ($scope.sort == "size") {
                $scope.recs.sort( function(a, b){
                    return ( a.count < b.count ) ? 1 : -1;
                });
            }
            var dispArray = new Array();
            var length = $scope.recs.length;
            for(var j = 0; j < length; j++) {
                var rec = $scope.recs[j];
                if (rec.digest.indexOf($scope.filterVal) > -1) {
                    dispArray.push(rec);
                }
                else if (rec.template.indexOf($scope.filterVal) > -1) {
                    dispArray.push(rec);
                }
            }
            $scope.filteredRecs = dispArray;
        }

        $scope.getFiltered = function() {
            console.log("getFiltered");
            var dispArray = new Array();
            if ($scope.recs.length==0) {
                return dispArray;
            }
            if ($scope.sort == "digest") {
                $scope.recs.sort( function(a, b){
                    return ( a.digest > b.digest ) ? 1 : -1;
                });
            }
            else if ($scope.sort == "size") {
                $scope.recs.sort( function(a, b){
                    return ( a.count < b.count ) ? 1 : -1;
                });
            }
            var length = $scope.recs.length;
            for(var j = 0; j < length; j++) {
                var rec = $scope.recs[j];
                if (rec.digest.indexOf($scope.filterVal) > -1) {
                    dispArray.push(rec);
                }
                else if (rec.template.indexOf($scope.filterVal) > -1) {
                    dispArray.push(rec);
                }
            }
            $scope.filteredRecs = dispArray;
            length = dispArray.length;
            for(var j = 0; j < length; j++) {
                var rec = dispArray[j];
                if (rec.digest == $scope.search) {
                    if (j<4) {
                        //$scope.offset = 0;
                    }
                    else {
                        //$scope.offset = j - 4;
                    }
                }
            }
            dispArray = dispArray.slice($scope.offset);
            return dispArray;
        }
        $scope.isMarked = function(rec) {
            if ($scope.zingFolder != rec.folderLoc) {
                return false;
            }
            for (var idx=0; idx<rec.patts.length; idx++) {
                if (rec.patts[idx] == $scope.zingPat) {
                    return true;
                }
            }
            return false;
        }
    });