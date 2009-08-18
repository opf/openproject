require File.dirname(__FILE__) + '/../test_helper'

class ItemTest < ActiveSupport::TestCase
  fixtures :items, :backlogs

  def test_list_continuity_after_move  
    items(:three).backlog_id = items(:five).backlog_id
    params = {
      :id => items(:three).id,
      :item => { :parent_id => items(:five).id },
      :issue => { }
    }
    
    Item.update params
    
    positions = Item.find(:all, :conditions => "parent_id=0", :order => "position ASC").map{|i| i.position}

    positions.each_with_index do |position, index|
      assert_equal index + 1, position
    end
  end  
  
end
