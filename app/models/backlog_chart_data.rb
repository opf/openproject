class BacklogChartData < ActiveRecord::Base
  unloadable
  set_table_name 'backlog_chart_data'
  belongs_to :backlog
  
  def self.generate(backlog)
    # do not generate if end_date or start_date are not defined
    # or if the start date is still in the future
    # or if the backlog is already closed
    return nil if backlog.end_date.nil? || backlog.start_date.nil? ||
                  backlog.start_date > Date.today ||
                  backlog.is_closed?
    data_today = BacklogChartData.find :first, :conditions => ["backlog_id=? AND created_at=?", backlog.id, Date.today.to_formatted_s(:db)]

    scope = Item.sum('points', :conditions => ["backlog_id=? AND parent_id=0", backlog.id])
    done  = Item.sum('points', :include => {:issue => :status}, :conditions => ["parent_id=0 AND backlog_id=? AND issue_statuses.is_closed=?", backlog.id, true])
    wip   = 0 
    if data_today.nil?
      create :scope => scope, :done => done, :backlog_id => backlog.id, :created_at => Date.today.to_formatted_s(:db)
    else
      data_today.scope = scope
      data_today.done  = done
      data_today.wip   = wip
      data_today.save!
    end
    data_today
  end
  
  def self.fetch(options = {})
    backlog = Backlog.find(options[:backlog_id])
    generate backlog
    end_date = backlog.end_date || 30.days.from_now.to_date
    data = find_all_by_backlog_id backlog.id, :conditions => ["created_at>=? AND created_at<=?", backlog.start_date.to_formatted_s(:db), end_date.to_formatted_s(:db)], :order => "created_at ASC"
    
    return nil if data.nil? || data.length==0
    
    data_points = (end_date - data.first.created_at.to_date).to_i + 1
    scope = []
    done  = [] 
    days  = []
    
    data.each do |d|
      scope << d.scope
      done  << d.done
      days  << d.created_at
    end
    
    (1..(data_points-days.length)).to_a.each do |i|
      days << days.last + 1.day
    end

    scope = scope.fill(scope.last, scope.length, data_points - scope.length)
    
    speed = (done.last - done.first).to_f / done.length
    
    best  = [done.last]
    worst = [done.last]
    
    if done.length > 1
      while best.last < scope.last && best.last > 0 && (best.length+done.length <= scope.length)
        best << (best.last + speed*1.5).round(2)
      end
      best[best.length-1] = best.last > scope.last ? scope.last : best.last
    
      while worst.last < scope.last && worst.last > 0 && (worst.length+done.length <= scope.length)
        worst << (worst.last + speed*0.5).round(2)
      end
      worst[worst.length-1] = worst.last > scope.last ? scope.last : worst.last
    end
    
    {
      :days    => days,
      :scope   => scope,
      :scope_x => (0...scope.length).to_a,
      :done    => done,
      :done_x  => (0...done.length).to_a,
      :best    => best,
      :best_x  => (0...best.length).to_a.map{|n| n+done.length-1},
      :worst   => worst,
      :worst_x => (0...worst.length).to_a.map{|n| n+done.length-1}
    }
  end
end
