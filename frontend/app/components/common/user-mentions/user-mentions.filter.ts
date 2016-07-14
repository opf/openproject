angular
  .module('openproject.filters')
  .filter('UserMentionsFilter', function(UserMentions, PathHelper){
    function mentionsFilter(value):ng.IFilterService {
        return value.replace(/@([a-z\d_ ]+)\((\d+)\)/gi, '<a href="' + PathHelper.userPath('$2') +'">@$1</a>')
    }

    return mentionsFilter;
  });
