# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class Watcher < ActiveRecord::Base
  belongs_to :watchable, :polymorphic => true
  belongs_to :user
  
  validates_presence_of :user
  validates_uniqueness_of :user_id, :scope => [:watchable_type, :watchable_id]

  # Unwatch things that users are no longer allowed to view
  def self.prune(options={})
    if options.has_key?(:user)
      prune_single_user(options[:user], options)
    else
      pruned = 0
      User.find(:all, :conditions => "id IN (SELECT DISTINCT user_id FROM #{table_name})").each do |user|
        pruned += prune_single_user(user, options)
      end
      pruned
    end
  end
  
  protected
  
  def validate
    errors.add :user_id, :invalid unless user.nil? || user.active?
  end
  
  private
  
  def self.prune_single_user(user, options={})
    return unless user.is_a?(User)
    pruned = 0
    find(:all, :conditions => {:user_id => user.id}).each do |watcher|
      next if watcher.watchable.nil?
      
      if options.has_key?(:project)
        next unless watcher.watchable.respond_to?(:project) && watcher.watchable.project == options[:project]
      end
      
      if watcher.watchable.respond_to?(:visible?)
        unless watcher.watchable.visible?(user)
          watcher.destroy
          pruned += 1
        end
      end
    end
    pruned
  end
end
