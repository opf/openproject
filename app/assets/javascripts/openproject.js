//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

window.OpenProject = (function ($) {
 /**
   * OpenProject instance methods
   */
  var OP = function (options) {
    options = options || {};
    this.urlRoot = options.urlRoot || "";

    this.loginUrl = options.loginUrl || "";

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

        project.hname   = OpenProject.Helpers.hname(project.name, project.level);
        project.parents = parents.slice(0, -1); // make sure to pass a clone
        project.tokens  = OpenProject.Helpers.Search.tokenize(project.name);
        project.url     = openProject.getFullUrl('/projects/' + project.identifier) + "?jump=" +
                            encodeURIComponent(jQuery('meta[name="current_menu_item"]').attr('content'));

        return project;
      });
    };

    return function (url, callback) {
      var fetchArgs = Array.prototype.slice.call(arguments);
      if (typeof url === "function") {
        callback = url;
        url = undefined;
      }

      if (!url) {
        url = this.getFullUrl("/api/v2/projects/level_list.json");
      }

      if (this.projects) {
        callback.call(this, this.projects);
        return;
      }

      jQuery.getJSON(
        url,
        jQuery.proxy(function (data, textStatus, jqXHR) {
          this.projects = augment(this, data.projects);
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
        jQuery(container).attr("title", result.project && result.project.name || result.text);

        if (query.sterm === undefined) {
          query.sterm = jQuery.trim(query.term);
        }


        // fallback to base behavior
        if (result.matches === undefined) {
          return replaceSpecialChars(
                  Helpers.markupEscape(format(result.text, query.term)));
        }

        // shortcut for empty searches
        if (query.sterm.length === 0) {
          return Helpers.markupEscape(result.text);
        }

        var matches = result.matches.slice(),
            text = result.text,
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
      var addUnmatchedParents = function (projects, matches, previousMatchId) {
        var i, project, result = [];

        jQuery.each(matches, function (i, match) {
          var previousParents;
          var unmatchedParents = [];
          var parents = match.project.parents.clone();

          if (i > 0) {
            previousParents = result[result.length - 1].project.parents.clone();
            previousParents.push(result[result.length - 1]);
          }

          var k;
          for (k = 0; k < parents.length; k += 1) {
            if (typeof previousParents == "undefined" || typeof previousParents[k] == "undefined")
              break;

            if (previousParents[k].id !== parents[k].id)
              break;
          }

          for (; k < parents.length; k += 1) {
            result.push(parents[k]);
          }

          result.push(match);
        });

        result = result.map(function (obj) {
          if (typeof obj.text === "undefined") {
            return {text: obj.hname};
          }

          return obj;
        });

        return result;
      };

      return function (query) {
        query.sterm = jQuery.trim(query.term);

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

          // perf optimization - when term is '', then all project will have
          // been matched and there will be no unmatched parents
          if (query.sterm.length > 0) {
            matches = addUnmatchedParents(projects, matches, context.lastMatchId);
          }

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

    Helpers.accessibilityModeEnabled = function() {
      return jQuery('meta[name="accessibility-mode"]').attr('content') === 'true';
    };

    return Helpers;
  })();

  return OP;
})(jQuery);
