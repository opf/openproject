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

module ProjectsHelper
  def link_to_version(version, options = {})
    return '' unless version && version.is_a?(Version)
    link_to version.name, {:controller => 'projects',
                           :action => 'roadmap',
                           :id => version.project_id,
                           :completed => (version.completed? ? 1 : nil),
                           :anchor => version.name
                          }, options
  end
  
  # Generates a gantt image
  # Only defined if RMagick is avalaible
  def gantt_image(events, date_from, months, zoom)
    date_to = (date_from >> months)-1    
    show_weeks = zoom > 1
    show_days = zoom > 2
    
    subject_width = 320
    header_heigth = 18
    # width of one day in pixels
    zoom = zoom*2
    g_width = (date_to - date_from + 1)*zoom
    g_height = 20 * events.length + 20
    headers_heigth = (show_weeks ? 2*header_heigth : header_heigth)
    height = g_height + headers_heigth
        
    imgl = Magick::ImageList.new
    imgl.new_image(subject_width+g_width+1, height)
    gc = Magick::Draw.new
    
    # Subjects
    top = headers_heigth + 20
    gc.fill('black')
    gc.stroke('transparent')
    gc.stroke_width(1)
    events.each do |i|
      gc.text(4, top + 2, (i.is_a?(Issue) ? i.subject : i.name))
      top = top + 20
    end

    # Months headers
    month_f = date_from
    left = subject_width
    months.times do 
      width = ((month_f >> 1) - month_f) * zoom
      gc.fill('white')
      gc.stroke('grey')
      gc.stroke_width(1)
      gc.rectangle(left, 0, left + width, height)
      gc.fill('black')
      gc.stroke('transparent')
      gc.stroke_width(1)
      gc.text(left.round + 8, 14, "#{month_f.year}-#{month_f.month}")
      left = left + width
      month_f = month_f >> 1
    end
    
    # Weeks headers
    if show_weeks
    	left = subject_width
    	height = header_heigth
    	if date_from.cwday == 1
    	    # date_from is monday
            week_f = date_from
    	else
    	    # find next monday after date_from
    		week_f = date_from + (7 - date_from.cwday + 1)
    		width = (7 - date_from.cwday + 1) * zoom
            gc.fill('white')
            gc.stroke('grey')
            gc.stroke_width(1)
            gc.rectangle(left, header_heigth, left + width, 2*header_heigth + g_height-1)
    		left = left + width
    	end
    	while week_f <= date_to
    		width = (week_f + 6 <= date_to) ? 7 * zoom : (date_to - week_f + 1) * zoom
            gc.fill('white')
            gc.stroke('grey')
            gc.stroke_width(1)
            gc.rectangle(left.round, header_heigth, left.round + width, 2*header_heigth + g_height-1)
            gc.fill('black')
            gc.stroke('transparent')
            gc.stroke_width(1)
            gc.text(left.round + 2, header_heigth + 14, week_f.cweek.to_s)
    		left = left + width
    		week_f = week_f+7
    	end
    end
    
    # Days details (week-end in grey)
    if show_days
    	left = subject_width
    	height = g_height + header_heigth - 1
    	wday = date_from.cwday
    	(date_to - date_from + 1).to_i.times do 
          width =  zoom
          gc.fill(wday == 6 || wday == 7 ? '#eee' : 'white')
          gc.stroke('grey')
          gc.stroke_width(1)
          gc.rectangle(left, 2*header_heigth, left + width, 2*header_heigth + g_height-1)
          left = left + width
          wday = wday + 1
          wday = 1 if wday > 7
    	end
    end

    # border
    gc.fill('transparent')
    gc.stroke('grey')
    gc.stroke_width(1)
    gc.rectangle(0, 0, subject_width+g_width, headers_heigth)
    gc.stroke('black')
    gc.rectangle(0, 0, subject_width+g_width, g_height+ headers_heigth-1)
        
    # content
    top = headers_heigth + 20
    gc.stroke('transparent')
    events.each do |i|      
      if i.is_a?(Issue)       
        i_start_date = (i.start_date >= date_from ? i.start_date : date_from )
        i_end_date = (i.due_date <= date_to ? i.due_date : date_to )        
        i_done_date = i.start_date + ((i.due_date - i.start_date+1)*i.done_ratio/100).floor
        i_done_date = (i_done_date <= date_from ? date_from : i_done_date )
        i_done_date = (i_done_date >= date_to ? date_to : i_done_date )        
        i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
        
        i_left = subject_width + ((i_start_date - date_from)*zoom).floor 	
        i_width = ((i_end_date - i_start_date + 1)*zoom).floor                  # total width of the issue
        d_width = ((i_done_date - i_start_date)*zoom).floor                     # done width
        l_width = i_late_date ? ((i_late_date - i_start_date+1)*zoom).floor : 0 # delay width
  
        gc.fill('grey')
        gc.rectangle(i_left, top, i_left + i_width, top - 6)
        gc.fill('red')
        gc.rectangle(i_left, top, i_left + l_width, top - 6) if l_width > 0
        gc.fill('blue')
        gc.rectangle(i_left, top, i_left + d_width, top - 6) if d_width > 0
        gc.fill('black')
        gc.text(i_left + i_width + 5,top + 1, "#{i.status.name} #{i.done_ratio}%")
      else
        i_left = subject_width + ((i.start_date - date_from)*zoom).floor
        gc.fill('green')
        gc.rectangle(i_left, top, i_left + 6, top - 6)        
        gc.fill('black')
        gc.text(i_left + 11, top + 1, i.name)
      end
      top = top + 20
    end
    
    # today red line
    if Date.today >= @date_from and Date.today <= @date_to
      gc.stroke('red')
      x = (Date.today-@date_from+1)*zoom + subject_width
      gc.line(x, headers_heigth, x, headers_heigth + g_height-1)      
    end    
    
    gc.draw(imgl)
    imgl
  end if Object.const_defined?(:Magick)
  
  def new_issue_selector
    trackers = Tracker.find(:all, :order => 'position')
    # can't use form tag inside helper
    content_tag('form',
      select_tag('tracker_id', '<option></option' + options_from_collection_for_select(trackers, 'id', 'name'), :onchange => "if (this.value != '') {this.form.submit()}"),
      :action => url_for(:controller => 'projects', :action => 'add_issue', :id => @project), :method => 'get')
  end
end
