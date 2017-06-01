//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

// ╭───────────────────────────────────────────────────────────────╮
// │  _____ _                _ _                                   │
// │ |_   _(_)_ __ ___   ___| (_)_ __   ___  ___                   │
// │   | | | | '_ ` _ \ / _ \ | | '_ \ / _ \/ __|                  │
// │   | | | | | | | | |  __/ | | | | |  __/\__ \                  │
// │   |_| |_|_| |_| |_|\___|_|_|_| |_|\___||___/                  │
// ├───────────────────────────────────────────────────────────────┤
// │ Javascript library that fetches and plots timelines for the   │
// │ OpenProject timelines module.                                 │
// ╰───────────────────────────────────────────────────────────────╯

module.exports = function(PathHelper) {

  Project = {
    objectType: 'Project',
    identifier: 'projects',

    is: function(t) {
      if (t === undefined) return false;
      return Project.identifier === t.identifier;
    },
    hide: function () {
      var hidden =  this.hiddenForEmpty() ||
                    this.hiddenForTimeFrame();

      this.hide = function () { return hidden; };

      return hidden;
    },
    hiddenForEmpty: function () {
      if (this.timeline.options.exclude_empty !== 'yes') {
        return false;
      }

      var hidden = true;
      // iterates over projects for second level grouping adjustments.
      // TODO simply hiding parents might be sufficient.
      jQuery.each(this.getPlanningElements(), function (i, child) {
        if (!child.filteredOut()) {
          hidden = false;
        }
      });

      return hidden;
    },
    hiddenForTimeFrame: function () {
      var types = this.timeline.options.planning_element_time_types;
      if (!types || types.length === 0) {
        return false;
      }

      var hidden = true;

      // we need to look at every element
      jQuery.each(this.getPlanningElements(), function (i, child) {
        // if hidden is already false, do not calculate
        // otherwise, we show this project current element is a planning element (redundant?)
        // and it is inside our timeframe
        // and it has got the planning element type we want
        if (hidden &&
              child.is(PlanningElement) &&
              child.inTimeFrame() &&
              Timeline.idInArray(types, child.getPlanningElementType())) {
                hidden = false;
        }
      });

      return hidden;
    },
    filteredOut: function() {
      var filtered = this.filteredOutForExclusionOfOwnPlanningElements() ||
                     this.filteredOutForExclusionOfReporters() ||
                     this.filteredOutForTypes() ||
                     this.filteredOutForStatus() ||
                     this.filteredOutForSubproject() ||
                     this.filteredOutForResponsibles();

      this.filteredOut = function () { return filtered; };

      return filtered;
    },
    filteredOutForExclusionOfOwnPlanningElements: function () {
      return (this.timeline.options.exclude_own_planning_elements === 'yes' &&
              (this.id === this.timeline.options.project_id ||
               this.identifier === this.timeline.options.project_id));
    },
    filteredOutForExclusionOfReporters: function() {
      return (this.timeline.options.exclude_reporters === 'yes' &&
              !(this.id === this.timeline.options.project_id ||
                this.identifier === this.timeline.options.project_id));
    },
    filteredOutForSubproject: function() {
      var i, j, p;
      var allowedParents = this.timeline.options.parents;

      if ((allowedParents === undefined) ||
          (allowedParents.length === 0)) {

        // if there is no filter, do not filter out anything.
        return false;

      } else {

        // for every id selected in the filter
        for (i = 0; i < allowedParents.length; i++) {

          j = Timeline.pnum(allowedParents[i]);

          if (j === -1) {
            // if the current selection is the (none) selection, we only need to
            // check the project's immediate parent. If it has none, it should
            // be shown, thus *not* filtered.
            if (this.parent === undefined) {
              return false;
            }
          }
          else {
            // if this project or one of it's ancestors has an id that is
            // equal to the current selection, it should be shown, thus *not*
            // filtered.
            p = this;
            while (p !== undefined) {
              if (p.id === j) {
                return false;
              } else {
                p = p.parent;
              }
            }
          }

        }

        // everything that was not decided to be *not* filtered until now should
        // be filtered.
        return true;
      }
    },
    filteredOutForResponsibles: function() {
      return Timeline.filterOutBasedOnArray(
        this.timeline.options.project_responsibles,
        this.getResponsible()
      );
    },
    filteredOutForStatus: function() {
      return Timeline.filterOutBasedOnArray(
        this.timeline.options.project_status,
        this.getProjectStatus()
      );
    },
    filteredOutForTypes: function() {
      return Timeline.filterOutBasedOnArray(this.timeline.options.project_types,
                                            this.getProjectType());
    },
    getPlanningElementType: function() {
      return undefined;
    },
    getPlanningElements: function() {
      if (!this.planning_elements) {
        return [];
      }
      if (!this.sorted_pes) {
        this.sort('planning_elements');
        this.sorted_pes = true;
      }
      return this.planning_elements;
    },
    getFirstLevelGroupingData: function() {
      return this.timeline.getGroupForProject(this);
    },
    getFirstLevelGrouping: function() {
      return this.timeline.getGroupForProject(this).number;
    },
    getFirstLevelGroupingName: function() {
      return this.timeline.getGroupForProject(this).name;
    },
    sort: function(field) {
      var timeline = this.timeline;
      this[field] = this[field].sort(function(a, b) {

        // order by inverse grouping, date, name, id
        var dc = 0, nc = 0;
        var as = a.start(), bs = b.start();
        var ag, bg;
        if (a.is(Project) && b.is(Project)) {
          var dataAGrouping = a.getFirstLevelGroupingData();
          var dataBGrouping = b.getFirstLevelGroupingData();

          // order first level grouping.
          if (parseInt(dataAGrouping.id, 10) !== parseInt(dataBGrouping.id, 10)) {
            /** other is always at bottom */
            if (parseInt(dataAGrouping.id, 10) === 0) {
              return 1;
            } else if (parseInt(dataBGrouping.id, 10) === 0) {
              return -1;
            }

            if (parseInt(timeline.options.grouping_one_sort, 10) === 1) {
              ag = dataAGrouping.number;
              bg = dataBGrouping.number;
            } else {
              ag = dataAGrouping.p.name;
              bg = dataBGrouping.p.name;
            }

            if (ag > bg) {
              return 1;
            }

            return -1;
          }
        }

        var datesEqual = as && bs && as.equals(bs);

        if ((!as || datesEqual) && typeof a.end === "function") {
          as = a.end();
        }
        if ((!bs || datesEqual) && typeof b.end === "function") {
          bs = b.end();
        }

        if (as) {
          if (bs) {
            dc = as.compareTo(bs);
          } else {
            dc = 1;
          }
        } else if (bs) {
          dc = -1;
        }

        var identifier_methods = [a, b].map(function(e) { return e.hasOwnProperty("subject") ? "subject" : "name"; });

        if (!a.identifierLower) {
          a.identifierLower = a[identifier_methods[0]].toLowerCase();
        }

        if (!b.identifierLower) {
          b.identifierLower = b[identifier_methods[1]].toLowerCase();
        }

        if (a.identifierLower < b.identifierLower) {
          nc = -1;
        }
        if (a.identifierLower > b.identifierLower) {
          nc = +1;
        }

        if (parseInt(timeline.options.project_sort, 10) === 1 && a.is(Project) && b.is(Project)) {
          if (nc !== 0) {
            return nc;
          }

          if (dc !== 0) {
            return dc;
          }
        } else {
          if (dc !== 0) {
            return dc;
          }

          if (nc !== 0) {
            return nc;
          }
        }

        if (a.id > b.id) {
          return +1;
        } else if (a.id < b.id) {
          return -1;
        }
        return 0;
      });
      return this;
    },
    start: function() {
      var i, current, pes = this.getPlanningElements();
      for (i = 0; i < pes.length; i += 1) {
        current = pes[i];
        if (current.start()) {
          return current.start();
        } else if (current.end()) {
          return current.end();
        }
      }

      return undefined;
    },
    getAttribute: function (val) {
      if (typeof this[val] === "function") {
        return this[val]();
      }

      return this[val];
    },
    does_historical_differ: function () {
      return false;
    },
    getReporters: function() {
      if (!this.reporters) {
        return [];
      }
      if (!this.sorted_reps) {
        this.sort('reporters');
        this.sorted_reps = true;
      }
      return this.reporters;
    },
    addReporter: function(rep) {
      var reps = this.getReporters();
      if (jQuery.inArray(rep, reps) === -1) {
        reps.push(rep);
        this.reporters = reps;
        this.sorted_reps = false;
        return true;
      }
      return false;
    },
    removeReporter: function(rep) {
      // this fails silently, when reporter to be removed is not in the list reporters.
      var new_reporters = jQuery.grep(this.getReporters(), function(e, i) {
          return e.id !== rep.id;
        });
      this.reporters = new_reporters;
      // we are not resetting sorted_reps, since removal does not affect sortation.
    },
    getProjectStatus: function() {
      return this.via_reporting !== undefined ? this.via_reporting.getStatus() : null;
    },
    getTypeName: function () {
      var pt = this.getProjectType();
      if (pt) {
        return pt.name;
      }
    },
    getStatusName: function () {
      var status = this.getProjectStatus();
      if (status) {
        return status.name;
      }
    },
    getProjectType: function() {
      return (this.project_type !== undefined) ? this.project_type : null;
    },
    getResponsible: function() {
      if (this.responsible !== undefined) {
        return this.responsible;
      } else if (this.responsible_id !== undefined && this.responsible_id !== null) {
        return { "id": this.responsible_id };
      } else {
        return null;
      }
    },
    getResponsibleName: function()  {
      if (this.responsible && this.responsible.name) {
        return this.responsible.name;
      }
    },
    getAssignedName: function () {
      return;
    },
    getSubElements: function() {
      var result = [];

      jQuery.each(this.getPlanningElements(), function(i, e) {
        // filtering of planning elements now happens in iterateWithChildren
        result.push(e);
      });

      jQuery.each(this.getReporters(), function(i, e) {
        // filtering of projects still happens here.
        if (!e.filteredOut()) {
          result.push(e);
        }
      });

      return result;
    },
    getParent: function() {
      var parent;
      if(!this.parent) return null;
      parent = this.timeline.getProject(this.parent.id);

      this.parent = parent;
      this.getParent = function() { return this.parent; };

      return this.getParent();
    },
    getUrl: function() {
      var url = PathHelper.projectPath(this.identifier);

      url += "/timelines";

      return url;
    },



    render: function(node) {
      if (node.isExpanded()) {
        return false;
      }

      var timeline = this.timeline;
      var scale = timeline.getScale();
      var beginning = timeline.getBeginning();
      var milestones, others;

      // draw all planning elements that should be seen in an
      // aggregation. limited to one level.

      var pes = jQuery.grep(this.getPlanningElements(), function(e) {
        return e.start() !== undefined &&
               e.end() !== undefined &&
               e.planning_element_type.in_aggregation;
      });

      var dummy_node = {
        getDOMElement: function() {
          return node.getDOMElement();
        },
        isExpanded: function() {
          return false;
        }
      };

      var is_milestone = function(e, i) {
        var pet = e.getPlanningElementType();
        return pet && pet.is_milestone;
      };

      // The label_spaces object will contain available spaces per
      // planning element. There may be many.
      var label_spaces = {};

      var render = function(i, e) {
        var node = jQuery.extend({}, dummy_node, {
          getData: function() { return e; }
        });
        e.render(node, true, label_spaces[i]);
        e.renderForeground(node, true, label_spaces[i]);
      };

      var visible_in_aggregation = function(e, i) {
        var pet = e.getPlanningElementType();
        return !e.filteredOut() && pet && pet.in_aggregation;
      };

      // divide into milestones and others.
      milestones = jQuery.grep(pes, is_milestone);
      others = jQuery.grep(pes, is_milestone, true);

      // join others with milestones, and remove all that should be filtered.
      pes = jQuery.grep(others.concat(milestones), visible_in_aggregation);

      // Outer loop to calculate best label space for each planning
      // element. Here, we initialize possible spaces by registering the
      // whole element as the single space for a label.
      jQuery.each(pes, function(i, e) {

        var b = e.getHorizontalBounds(scale, beginning);
        label_spaces[i] = [b];

        // find all pes above the one we're traversing.
        var passed_self = false;
        var pes_to_traverse = jQuery.grep(pes, function(f) {
          return passed_self || (e === f) ? passed_self = true : false;
        });

        // Now, for every other element , shorten the available spaces or splice them.
        jQuery.each(pes_to_traverse, function(j, f) {
          var k, cb = f.getHorizontalBounds(scale, beginning, is_milestone(f));

          // do not shorten if I am looking at myself.
          if (e === f) {
            return;
          }

          // do not shorten if current element is not a milestone and
          // begins before me.
          if (!is_milestone(f) && cb.x < b.x) {
            return;
          }

          // do not shorten if both are milestones and current begins before me.
          if (is_milestone(f) && is_milestone(e) && cb.x < b.x) {
            return;
          }

          // do not shorten if I am a milestone and current element is not.
          if (is_milestone(e) && !is_milestone(f)) {
            return;
          }

          // iterate over actual spaces left for shortening or splicing.
          var spaces = label_spaces[i];
          for (k = 0; k < spaces.length; k++) {
            var space = spaces[k];

            // b  eeeeeeee
            //cb       fffffffffff

            // current element lies after me,
            var rightSideOverlap = cb.x > space.x &&
                    // but I do end after its start.
                    cb.x < space.end();

            // b           eeeeeeeeeee
            //cb    ffffffffffff

            // current element lies before me
            var leftSideOverlap = cb.end() < space.end() &&
                      // but I start before current elements end.
                      cb.end() > space.x;

            if ((cb.x <= space.x && cb.end() >= space.end()) &&
                (label_spaces[i].length > 0)) {
              if (label_spaces[i].length === 1) {
                label_spaces[i][0].w = 0;
              } else {
                label_spaces[i].splice(k, 1);
              }
            }

            //  fffffffeeeeeeeeeeeeffffffffff

            if (rightSideOverlap && leftSideOverlap) {

              // if current planning element is completely enclosed
              // in the current space, split the space into two, and
              // reiterate. splitting happens by splicing the array at
              // position i.
              label_spaces[i].splice(k, 1,
                {'x': space.x,
                 'w': cb.x - space.x, end: space.end},
                {'x': cb.end(),
                 'w': space.end() - cb.end(), end: space.end});

            } else if (rightSideOverlap) {

              // if current planning element (f) starts before the one
              // current space ends, adjust the width of the space.
              space.w = Math.min(space.end(), cb.x) - space.x;

            } else if (leftSideOverlap) {

              // if current planning element (f) ends after the current
              // space starts, adjust the beginning of the space.
              // we also need to modify the width because we want to
              // keep the end at the same position.
              var oldStart = space.x;
              space.x = Math.max(space.x, cb.end());
              space.w -= (space.x - oldStart);
            }
          }
        });

        // after all possible label spaces for the given element are
        // evaluated, select the widest.
        b = label_spaces[i].shift();
        jQuery.each(label_spaces[i], function(i, e) {
          if (e.w > b.w) {
            b = e;
          }
        });
        label_spaces[i] = b;
      });

      // jQuery.each(others, render);
      // jQuery.each(milestones, render);
      jQuery.each(pes, render);
    },
    getElements: function() {
      return [];
    },
    all: function(timeline) {
      // collect all planning elements
      var r = timeline.projects;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    }
  };

  return Project;
};
