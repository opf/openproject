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

class HelpController < ApplicationController
	
  skip_before_filter :check_if_login_required
	before_filter :load_help_config

	def index	
		if @params[:ctrl] and @help_config[@params[:ctrl]]
			if @params[:page] and @help_config[@params[:ctrl]][@params[:page]]
				template = @help_config[@params[:ctrl]][@params[:page]]
			else
				template = @help_config[@params[:ctrl]]['index']
			end
		end
		
    if template
      redirect_to "/manual/#{template}"
    else
      redirect_to "/manual/"
    end
	end

private
	def load_help_config
		@help_config = YAML::load(File.open("#{RAILS_ROOT}/config/help.yml"))
	end	
end
