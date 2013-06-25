window.OpenProject = (function ($) {
 /**
   * OpenProject instance methods
   */
  var OP = function (options) {
    options = options || {};
    this.urlRoot = options.urlRoot || "";

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

  OP.prototype.fetchProjects = (function () {
    var augment = function (openProject, projects) {
      var parents = [], currentLevel = -1;

      return jQuery.map(projects, function (project) {
        while (currentLevel >= project.level) {
          parents.pop();
          currentLevel--;
        }
        parents.push(project);
        currentLevel = project.level;
        project.project = project;
        project.hname   = OpenProject.Helpers.hname(project.name, project.level);
        project.parents = parents.slice(0, -1); // make sure to pass a clone
        project.tokens  = OpenProject.Helpers.Search.tokenize(project.name);
        project.url     = openProject.getFullUrl('/projects/' + project.identifier) + "?jump=" +
                            encodeURIComponent(jQuery('meta[name="current_menu_item"]').attr('content'));

        return project;
      });
    };

    return function (url, callback) {
      if (!this.projects) {
        this.projects = {};
      }

      var fetchArgs = Array.prototype.slice.call(arguments);
      if (typeof url === "function") {
        callback = url;
        url = undefined;
      }

      if (!url) {
        url = this.getFullUrl("/projects/level_list.json");
      }

      if (this.projects[url]) {
        callback.call(this, this.projects[url]);
        return;
      }

      jQuery.getJSON(
        url,
        jQuery.proxy(function (data) {
          this.projects[url] = augment(this, data.projects);
          this.fetchProjects.apply(this, fetchArgs);
        }, this)
      );
    };
  })();

  /**
   * Static OpenProject Helper methods
   */

  OP.Helpers = (function () {
    var Helpers = {};

    Helpers.hname = function (name, level) {
      var l, prefix = '';

      if (level > 0) {
        for (l = 0; l < level; l++) {
          prefix += '\u00A0\u00A0\u00A0'; // &nbsp;&nbsp;&nbsp;
        }
        prefix += '\u00BB\u00A0'; // &raquo;&nbsp;
      }

      return prefix + name;
    };


    var REGEXP_ESCAPE = /([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\|\:\!><])/g;

    /**
     * Escapes regexp special chars, e.g. to make sure, that users cannot enter
     * regexp syntax but just plain strings.
     */
    Helpers.regexpEscape = function (str) {
      // taken from http://stackoverflow.com/questions/280793/
      return (str+'').replace(REGEXP_ESCAPE, "\\$1");
    };

    /**
     * Use select2's escapeMarkup function for correctly escaping
     * text and preventing XSS.
     */
    Helpers.markupEscape = (function(){
      try {
        var escapeMarkup = jQuery.fn.select2.defaults.escapeMarkup;
        if(typeof escapeMarkup === "undefined") {
          throw 'jQuery.fn.select2.defaults.escapeMarkup is undefined';
        }
        return escapeMarkup;
      } catch (e){
        console.log('Error: jQuery.fn.select2.defaults.escapeMarkup not found.\n' +
                    'Exception: ' + e.toString());
        throw e;
      }
    }());

    /**
     * replace wrong with right in text
     *
     * Matches case insensitive and performs atmost one replacement.
     * This is a faster version of
     *
     *   text.replace(new RegExp(Helpers.regexpEscape(wrong), 'i'), right)
     *
     * ... at least for some browsers. Performs twice as fast on Chrome 23,
     * 20 % faster on FF 18.
     */
    Helpers.replace = function (text, wrong, right) {
      var matchStart;

      if (wrong.length === 0) {
        return text;
      }

      matchStart = text.toUpperCase().indexOf(wrong.toUpperCase());

      if (matchStart < 0) {
          return text;
      }

      return text.substring(0, matchStart) +
             right +
             text.substring(matchStart + wrong.length);
    };


    /**
     * Removes element from array - but only once.
     *
     *    a = [1, 2, 3, 2, 1];
     *    b = withoutOnce(a, 1);
     *
     *    b;      // => [2, 3, 2, 1]
     *    a === b // false
     */
    Helpers.withoutOnce = function (array, element) {
      var removed = false;
      return jQuery.grep(array, function (t) {
        if (removed) {
          return true;
        }
        if (t === element) {
          removed = true;
          return false;
        }
        return true;
      });
    };

    Helpers.Search = {};

    var REGEXP_TOKEN = /[\s\.\-\/,]+/;

    Helpers.Search.tokenize = function (name, separators) {
      var regexp;

      if (jQuery.isArray(separators)) {
        regexp = new RegExp(Helpers.regexpEscape(separators.join("")) + "+");
      }
      else if (separators instanceof RegExp) {
        regexp = separators;
      }
      else {
        regexp = REGEXP_TOKEN;
      }

      return jQuery.grep(name.split(regexp), function (t) { return t.length > 0; });
    },

    Helpers.Search.formatter = (function () {
      var START_OF_TEXT   = "\u2402",
          END_OF_TEXT     = "\u2403";
          R_START_OF_TEXT = new RegExp(START_OF_TEXT, "g"),
          R_END_OF_TEXT   = new RegExp(END_OF_TEXT,   "g");

      var format = function (text, term) {
        var matchStart, matchEnd;

        if (term.length === 0) {
          return text;
        }

        matchStart = text.toUpperCase().indexOf(term.toUpperCase());

        if (matchStart < 0) {
            return text;
        }

        matchEnd = matchStart + term.length;

        return text.substring(0, matchStart) +
               START_OF_TEXT +
               text.substring(matchStart, matchEnd) +
               END_OF_TEXT +
               text.substring(matchEnd);
      };

      var replaceSpecialChars = function (text) {
        return text.replace(R_START_OF_TEXT, "<span class='select2-match'>").
                    replace(R_END_OF_TEXT,   "</span>");
      };

      return function (result, container, query) {
        var real_name = result.text || (result.project && result.project.name);
        jQuery(container).attr("title", real_name);

        if (query.sterm === undefined) {
          query.sterm = jQuery.trim(query.term);
        }


        // fallback to base behavior
        if (result.matches === undefined) {
          return replaceSpecialChars(
                  Helpers.markupEscape(format(real_name, query.term)));
        }

        // shortcut for empty searches
        if (query.sterm.length === 0) {
          return Helpers.markupEscape(result.text);
        }

        var matches = result.matches.slice(),
            text = real_name,
            match;

        while (matches.length) {
          match = matches.pop();
          text = Helpers.replace(text, match[0], format(match[0], match[1]));
        }

        return replaceSpecialChars(Helpers.markupEscape(text));
      };
    })();


    Helpers.Search.matcher = (function () {
      var match, matchMatrix,
          defaultMatcher = $.fn.select2.defaults.matcher;

      match = function (query, t) {
        return function (s) {
          return defaultMatcher.call(query, t, s);
        };
      };

      matchMatrix = function (query, parts, tokens, matches) {
        var part = parts[0],
            candidates = jQuery.grep(tokens, match(query, part));

        if (parts.length === 1) {
          // do the remaining tokens match the one remaining part?
          if (candidates.length > 0) {
            matches.push([candidates[0], part]);
            return true;
          }
          else {
            return false;
          }
        }

        parts = parts.slice(1);

        for (var i = 0; i < candidates.length; i++) {
          if (matchMatrix(query, parts, Helpers.withoutOnce(tokens, candidates[i]), matches)) {
            matches.push([candidates[i], part]);
            return true;
          }
        }

        return false;
      };

      return function (term, name, token) {
        var result, matches = [];

        if (match(this, term)(name)) {
          matches.push([name, term]);
          result = true;
        }
        else if (token === undefined) {
          result = false;
        }
        else {
          result = matchMatrix(this, Helpers.Search.tokenize(term, /\s+/), token, matches);
        }

        return result ? matches : false;
      };
    })();

    Helpers.Search.projectQueryWithHierarchy = function (fetchProjects, pageSize) {
      var savedPreviousResult;

      var addUnmatchedAndSelectedParents = function (projects, matches, previousMatchId) {
        var result = [], selected_choices = (this.element.val() === "" ? [] : this.element.val().split(",").map(function (e) {
            return parseInt(e, 10);
        }));

        jQuery.each(matches, function (i, match) {
          if ($.inArray(match.id, selected_choices) > -1 || match.project.disabled) {
            return;
          }

          var previousParents, previousResult;
          var parents = match.project.parents.clone();
          match.disabled = false;

          //if we have a previous result get this results parents
          if (result.length > 0) {
            previousResult = result[result.length - 1];
          } else if (previousMatchId && savedPreviousResult) {
            previousResult = savedPreviousResult;
          }

          if (previousResult) {
            previousParents = previousResult.project.parents.clone();
            previousParents.push(previousResult);
          }

          var k;
          for (k = 0; k < parents.length; k += 1) {
            if (typeof previousParents == "undefined" || typeof previousParents[k] == "undefined")
              break;

            if (previousParents[k].id !== parents[k].id)
              break;
          }

          for (; k < parents.length; k += 1) {
            result.push({
              id      : parents[k].id,
              text    : parents[k].hname,
              project : parents[k],
              disabled: true
            });
          }

          savedPreviousResult = match;

          result.push(match);
        });

        //remove ids of all elements that are disabled.
        result.each(function (ele) {
          if (ele.disabled) {
            delete ele.id;
          } 

          ele.disabled = false;
        });

        return result;
      };

      return function (query) {
        query.sterm = jQuery.trim(query.term);
        var select2Object = this;

        fetchProjects(function (projects) {
          var context = query.context || {},
              matches = [],
              project, matchPairs;

          context.i = context.i ? context.i + 1 : 0;

          for (context.i; context.i < projects.length; context.i++) {
            project = projects[context.i];

            matchPairs = query.matcher(query.sterm, project.name, project.tokens);
            if (matchPairs) {
              matches.push({
                id      : project.id,
                text    : project.hname,
                project : project,
                matches : matchPairs
              });
            }

            if (matches.length === pageSize) {
              break;
            }
          }

          matches = addUnmatchedAndSelectedParents.call(select2Object, projects, matches, context.lastMatchId);

          // store last match for next page
          if (matches.length > 0) {
            context.lastMatchId = matches[matches.length - 1].id;
          }
          else {
            context.lastMatchId = undefined;
          }

          query.callback.call(query, {
            results : matches,
            more    : context.i < projects.length,
            context : context
          });
        });
      };
    };

    return Helpers;
  })();

  return OP;
})(jQuery);
