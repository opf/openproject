#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

class MeetingParticipant < ActiveRecord::Base

  belongs_to :meeting
  belongs_to :user

  scope :invited, conditions: {invited: true}
  scope :attended, conditions: {attended: true}

  attr_accessible :email, :name, :invited, :attended, :user, :user_id, :meeting

  User.before_destroy do |user|
    MeetingParticipant.update_all ['user_id = ?', DeletedUser.first], ['user_id = ?', user.id]
  end

  def name
    user.present? ? user.name : self.name
  end

  def mail
    user.present? ? user.mail : self.mail
  end

  def <=>(participant)
    self.to_s.downcase <=> participant.to_s.downcase
  end

  alias :to_s :name

  def copy_attributes
    #create a clean attribute set allowing to attach participants to different meetings
    self.attributes.reject { |k,v| ['id','meeting_id','attended','created_at', 'updated_at'].include?(k)}
  end
end
