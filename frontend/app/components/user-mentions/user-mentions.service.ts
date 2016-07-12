import {HalResource} from "../api/api-v3/hal-resources/hal-resource.service";
import {WorkPackageResourceInterface} from '..//api/api-v3/hal-resources/work-package-resource.service';

export class UserMentions {
  // expose the watchers to our filter
  public availableWatchers: any = [];

  constructor(protected $q:ng.IQService,
              protected $http:ng.IHttpService,
              protected wpWatchers, 
              protected wpCacheService,
              protected PathHelper){}

  public loadAvailableWatchers(wp:WorkPackageResourceInterface){
    var availableWatchers = this.$q.defer();

    this.$http.get((wp.availableWatchers as HalResource).href).then((res)=>{
      this.availableWatchers.length = 0;
      angular.extend(this.availableWatchers, res.data._embedded.elements);
      availableWatchers.resolve(this.availableWatchers);
    });

    return availableWatchers.promise;
  }

  public parseWatchers(wp: WorkPackageResourceInterface, parseText:string){
    if(parseText.length > 0){
      this.$http.get((wp.watchers as HalResource).href).then(currentWatchers =>{

        currentWatchers = currentWatchers.data._embedded.elements;

        var addMentionsQueue:Array<ng.IPromise> = [];
        var mention: any;
        var mentionRegExp: RegExp = /@([a-z\d_ ]+)\((\d+)\)/gi;

        while (mention = mentionRegExp.exec(parseText)) {
          var isAlreadyWatching = _.find(currentWatchers,
            (w)=>{
              return w.id === parseInt(mention[2]);
            });
          
          if(! isAlreadyWatching ){
            addMentionsQueue.push(this.wpWatchers.addForWorkPackage(wp,{
              href: '/api/v3/users/' + mention[2]
            }))
          }
        }

        this.$q.all(addMentionsQueue).then(()=>{
          // force update of watchers so they will be displayed on the
          // watchers tab
          this.wpCacheService.loadWorkPackageLinks(wp,['watchers']);
        })
      });
    }    
  }

}

angular.module("openproject.services").service("UserMentions",UserMentions);
