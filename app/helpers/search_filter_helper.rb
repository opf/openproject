# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module SearchFilterHelper

  def search_filter_criteria(name, options = {})
    @search_filter ||= {}
    @search_filter[name] ||= {}
    @search_filter[name][:options] = []
    @search_filter[name][:conditions] = {}
    yield.each { |c|
      @search_filter[name][:options] << [c[0], c[1].to_s]
      @search_filter[name][:conditions].store(c[1].to_s, c[2])
    }
  end

  def search_filter_update
    session[:search_filter] ||= {}
    @search_filter.each_key {|field| session[:search_filter][field] = params[field]  }
  end
	
  def search_filter_clause
    session[:search_filter] ||= {}
    clause = ["1=1"]
    @search_filter.each { |k, v|
      filter_value = session[:search_filter][k] || v[:options][0][1]
      if v[:conditions][filter_value]
        clause[0] = clause[0] + " AND " + v[:conditions][filter_value].first
        clause += v[:conditions][filter_value][1..-1]
      end    
    }
    clause
  end
	
  def search_filter_tag(criteria, options = {})
    session[:search_filter] ||= {}
    options[:name] = criteria
    options[:class] += " active-filter" if session[:search_filter][criteria] and session[:search_filter][criteria] != @search_filter[criteria][:options][0][1]
    content_tag("select", 
				options_for_select(@search_filter[criteria][:options], session[:search_filter][criteria]),
				options
				)
  end
	
  def search_filter_init_list_issues
	search_filter_criteria('status_id') { 
    [ [('['+l(:label_open_issues_plural)+']'), "O", ["issue_statuses.is_closed=?", false]],
      [('['+l(:label_closed_issues_plural)+']'), "C", ["issue_statuses.is_closed=?", true]],
      [('['+l(:label_all)+']'), "A", nil]
    ] + IssueStatus.find(:all).collect {|s| [s.name, s.id, ["issues.status_id=?", s.id]] }                                                      
    }
    
    search_filter_criteria('tracker_id') { 
    [ [('['+l(:label_all)+']'), "A", nil]
    ] + Tracker.find(:all).collect {|s| [s.name, s.id, ["issues.tracker_id=?", s.id]] }                                                      
    }
	
    search_filter_criteria('priority_id') { 
    [ [('['+l(:label_all)+']'), "A", nil]
    ] + Enumeration.find(:all, :conditions => ['opt=?','IPRI']).collect {|s| [s.name, s.id, ["issues.priority_id=?", s.id]] }                                                      
    }
    
    search_filter_criteria('category_id') { 
    [ [('['+l(:label_all)+']'), "A", nil],
      [('['+l(:label_none)+']'), "N", ["issues.category_id is null"]]
    ] + @project.issue_categories.find(:all).collect {|s| [s.name, s.id, ["issues.category_id=?", s.id]] }                                                      
    }    

    search_filter_criteria('fixed_version_id') { 
    [ [('['+l(:label_all)+']'), "A", nil],
      [('['+l(:label_none)+']'), "N", ["issues.fixed_version_id is null"]]
    ] + @project.versions.collect {|s| [s.name, s.id, ["issues.fixed_version_id=?", s.id]] }                                                      
    }

    search_filter_criteria('author_id') { 
    [ [('['+l(:label_all)+']'), "A", nil],
    ] + @project.users.collect {|s| [s.display_name, s.id, ["issues.author_id=?", s.id]] }                                                      
    }
    
    search_filter_criteria('assigned_to_id') { 
    [ [('['+l(:label_all)+']'), "A", nil],
      [('['+l(:label_none)+']'), "N", ["issues.assigned_to_id is null"]]
    ] + @project.users.collect {|s| [s.display_name, s.id, ["issues.assigned_to_id=?", s.id]] }                                                      
    }
    
    search_filter_criteria('subproject_id') { 
    [ [('['+l(:label_none)+']'), "N", ["issues.project_id=?", @project.id]],
      [('['+l(:label_all)+']'), "A", ["(issues.project_id=? or projects.parent_id=?)", @project.id, @project.id]]
    ]                                                     
    }  
  end
end