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
    session[:search_filter] ||= {}
    session[:search_filter][name] ||= {}
    unless session[:search_filter][name][:options] and session[:search_filter][name][:conditions]
      session[:search_filter][name][:options] = []
      session[:search_filter][name][:conditions] = {}
      yield.each { |c|
        session[:search_filter][name][:options] << [c[0], c[1].to_s]
        session[:search_filter][name][:conditions].store(c[1].to_s, c[2])
      }
    end
  end

  def search_filter_update
    session[:search_filter].each_key {|field| session[:search_filter][field][:value] = params[field]  }
  end
	
  def search_filter_clause
    clause = ["issues.project_id=?", @project.id]
    session[:search_filter].each { |k, v|
      v[:value] ||= v[:options][0][1]
      if (!v[:conditions][v[:value]][0].empty?)
        clause[0] = clause[0] + " AND " + v[:conditions][v[:value]][0]
        clause << v[:conditions][v[:value]][1] if !v[:conditions][v[:value]][1].nil?
      end    
    }
    clause
  end
	
  def search_filter_tag(criteria)
    content_tag("select", 
				options_for_select(session[:search_filter][criteria][:options], session[:search_filter][criteria][:value]),
				:name => criteria
				)
  end
	
  def search_filter_init_list_issues
	search_filter_criteria('status_id') { 
    [ ["[Open]", "O", ["issue_statuses.is_closed=?", false]],
      ["[All]", "A", ["", false]]
    ] + IssueStatus.find(:all).collect {|s| [s.name, s.id, ["issues.status_id=?", s.id]] }                                                      
    }
    
    search_filter_criteria('tracker_id') { 
    [ ["[All]", "A", ["", false]]
    ] + Tracker.find(:all).collect {|s| [s.name, s.id, ["issues.tracker_id=?", s.id]] }                                                      
    }
	
    search_filter_criteria('priority_id') { 
    [ ["[All]", "A", ["", false]]
    ] + Enumeration.find(:all, :conditions => ['opt=?','IPRI']).collect {|s| [s.name, s.id, ["issues.priority_id=?", s.id]] }                                                      
    }
    
    search_filter_criteria('category_id') { 
    [ ["[All]", "A", ["", false]],
      ["[None]", "N", ["issues.category_id is null"]]
    ] + @project.issue_categories.find(:all).collect {|s| [s.name, s.id, ["issues.category_id=?", s.id]] }                                                      
    }    

    search_filter_criteria('assigned_to_id') { 
    [ ["[All]", "A", ["", false]],
      ["[Nobody]", "N", ["issues.assigned_to_id is null"]]
    ] + User.find(:all).collect {|s| [s.display_name, s.id, ["issues.assigned_to_id=?", s.id]] }                                                      
    }   	
  end
end