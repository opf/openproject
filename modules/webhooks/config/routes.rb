#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

OpenProject::Application.routes.draw do
  namespace 'webhooks' do
    match ":hook_name", to: 'incoming/hooks#handle_hook', via: %i(get post)
  end

  scope 'admin' do
    resources :webhooks,
              param: :webhook_id,
              controller: 'webhooks/outgoing/admin',
              as: 'admin_outgoing_webhooks'
  end
end
