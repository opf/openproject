window.OpenProject = (function () {
  var OP = function (options) {
    this.urlRoot = options.urlRoot;

    if (!/\/$/.test(this.urlRoot)) {
      this.urlRoot += '/';
    }
  };

  OP.prototype.getFullUrl = function (url) {
    if (!url) {
      return this.urlRoot;
    }

    if (/^\//.test(url)) {
      url = url.substr(1);
    }

    return this.urlRoot + url;
  };

  OP.prototype.fetchProjects = function (callback) {
    if (this.projects) {
      callback.call(this, projects);
      return;
    }

    jQuery.getJSON(
        this.getFullUrl("/projects/level_list.json"),
        function (data, textStatus, jqXHR) {
          this.projects = data.projects;
          callback.call(this, this.projects);
        }
      );
  };

  return OP;
})();
