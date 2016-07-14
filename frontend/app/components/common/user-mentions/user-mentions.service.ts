import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';
import {
  WorkPackageResourceInterface,
  WorkPackageResource
} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {UserResource} from '../../api/api-v3/hal-resources/user-resource.service';

export class UserMentions {
  public availableWatchers: any = [];

  constructor(protected $http:ng.IHttpService,
              protected $q:ng.IQService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpWatchers) {}

  public loadAvailableWatchers(wp:WorkPackageResourceInterface):ng.IPromise<Array<UserResource>> {
    var availableWatchers = this.$q.defer();
    var wpResource: WorkPackageResource;

    var doLoading = (wp:WorkPackageResourceInterface):void => {
      // user is not allowed to see / add watchers
      if (!wp.availableWatchers) {
        availableWatchers.reject();
      } else {
        (wp as any).availableWatchers.$load().then((availableWatchersRequest) => {
          this.availableWatchers = availableWatchersRequest.$embedded.elements;
          availableWatchers.resolve(this.availableWatchers);
        });
      }
    };

    if (wp.isNew) {
      // Permissions are set for a given project and a user role but not specifically for 
      // wps. For wp creation we can access any wp of the same project to check permissions
      // and get a list of available watchers

      this.$http.get(wp.project.href + '/work_packages/').then((res:any) => {
        var sampleWp = res.data._embedded.elements[0];
        wpResource = new WorkPackageResource(sampleWp);
      });
    }else {
      wpResource = wp;
    }
    if (angular.isDefined(wpResource) && (wpResource as WorkPackageResourceInterface).availableWatchers) {
      doLoading((wpResource as WorkPackageResourceInterface));
    } else {
      availableWatchers.reject();
    }


    return availableWatchers.promise;
  }

  public parseWatchers(wp: WorkPackageResourceInterface, parseText:string) {
    if (angular.isDefined(wp) && parseText.length > 0) {
      (wp.watchers as any).$load().then((currentWatchers:any) => {
        currentWatchers = currentWatchers.$embedded.elements;

        var addMentionsQueue:Array<ng.IPromise<Array<UserResource>>> = [];
        var mention: any;
        var mentionRegExp: RegExp = /@([a-z\d_ ]+)\((\d+)\)/gi;

        while (mention = mentionRegExp.exec(parseText)) {
          var isAlreadyWatching:boolean = angular.isDefined(_.find(currentWatchers,
            (watcher:UserResource) => {
              return watcher.id === parseInt(mention[2]);
            }));

          if (!isAlreadyWatching) {
            addMentionsQueue.push(this.wpWatchers.addForWorkPackage(wp, {
              href: '/api/v3/users/' + mention[2]
            }));
          }
        }

        this.$q.all(addMentionsQueue).then(() => {
          // force update of watchers so they will be displayed on the
          // watchers tab
          this.wpCacheService.loadWorkPackageLinks(wp, 'watchers');
        });
      });
    }
  }
}

angular.module('openproject.services').service('UserMentions', UserMentions);
