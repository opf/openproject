#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Extending this module provides some convenience methods for easier setup of pagination inside a controller.
# It assumes there is just one pagination method to set up per model.
#
# To set up basic functions:
#   paginate_model Project
#
# This sets up the action #paginate_projects inside the controller.
#
# To change this action:
#
#   action_for Project, :my_own_action
#
# or use a block:
#
#   action_for Project do
#     do_something
#   end
#
# To set up multiple models at once:
# paginate_models Project, User
#
# To change the call the model uses for pagination (signature as in Pagination::Model#paginate_scope!):
#   pagination_for Project, :my_own_pagination_method
#   pagination_for Project do |scope, opts|
#     do_something
#   end
#
# To change the scope the model uses to search (signature as in Pagination::Model#search_scope):
#   search_for Project, :my_own_pagination_method
#   search_for Project do |query|
#     do_something
#   end
# Note that this needs to return an actual scope or its corresponding hash.
#
# To change the response the action will give:
# response_for Project, :my_custom_response
# response_for Project, Proc.new {
#                         respond_to do |format|
#                           DO SOMETHING
#                         end
#                       }
# This needs to return something that can be #instance_eval'ed AND #call'ed, i.e. a Proc.
# A String containing code will NOT work but a lambda will, if the execution context
# can be changed accordingly (simply providing an additional parameter will work in most
# cases).
#
# There are several possibilities to add options to the call to #search_method:
# Procs allow to change behaviour dynamically, as with ActiveRecords scopes.
# Lambdas will work just as procs, but an additional parameter needs to get passed to
#   change their context.
# Everything else just gets passed as is.
# search_options_for Project, proc { @bar.nil? ? @bar : { a: b, c: d } }
# search_options_for Project, lambda { |self| (@bar.nil? ? @bar : { a: b, c: d }) }
# search_options_for Project, { a: b, c: d }
# search_options_for Project, "yeah!"
#
#
module Pagination::Controller
  class Paginator
    attr_accessor :model, :action, :pagination, :search, :controller, :last_action, :block, :response, :search_options

    def initialize(controller, model)
      self.controller = controller
      self.model = model
    end

    def self.resolve_model(model)
      (model.respond_to?(:constantize) ? model.constantize : model)
    end

    def default_action
      model_name = self.class.resolve_model(model).name
      model_name_without_modules = model_name.split('::').last || ''
      :"paginate_#{model_name_without_modules.underscore.downcase.pluralize}"
    end

    def default_pagination
      :'paginate_scope!'
    end

    def default_search
      :search_scope
    end

    def default_search_options
      {}
    end

    def last_action
      @last_action ||= action
    end

    def action
      @action ||= default_action
    end

    def action=(action)
      @action = action
      refresh_action!
      @action
    end

    def search
      @search ||= default_search
    end

    def pagination
      @pagination ||= default_pagination
    end

    def block
      @block ||= default_block
    end

    def response
      @response ||= default_response_block
    end

    def search_options
      @search_options ||= default_search_options
    end

    def changed?
      last_action != action
    end

    def refresh_action!
      undef_action!
      define_action!
    end

    def undef_action!
      controller.pagination.delete(last_action)

      # remove old
      controller.send(:remove_method, last_action) if controller.respond_to? last_action
    end

    def define_action!(block = default_block)
      controller.pagination[action] = self
      raise NameError, "method '#{action}' already defined in #{controller}" if controller.respond_to? action
      controller.send(:define_method, action, block)
    end

    def default_block
      Proc.new {
        # TODO: less evilness
        paginator = self.class.pagination[__method__]
        size = params[:page_limit].to_i || 10
        page = params[:page]

        if page
          page = page.to_i

          methods = {}
          [:pagination, :search].each do |meth|
            methods[meth] = if paginator.send(meth).respond_to?(:call)
                              paginator.send(meth)
                            else
                              paginator.model.method(paginator.send(meth))
              end
          end

          if (options = paginator.search_options).respond_to?(:call)
            options = instance_eval(&(options.to_proc))
          end

          search_call = (options.presence ? methods[:search].call(params[:q], options) : methods[:search].call(params[:q]))
          @paginated_items = methods[:pagination].call(
            search_call,
            page: page, page_limit: size
          )

          @more = @paginated_items.total_pages > page
          @total = @paginated_items.total_entries

          instance_eval(&(paginator.response.to_proc))
        end
      }
    end

    def default_response_block
      Proc.new {
        respond_to do |format|
          format.json do
            render json: { results:
            { items: @paginated_items.map { |item| { id: item.id, name: item.name } },
              total: @total ? @total : @paginated_items.size,
              more:  @more ? @more : 0 }
          }
          end
        end
      }
    end
  end

  def self.included(base)
    base.extend self
  end

  def self.extended(base)
    base.instance_eval do
      def paginate_models(*args)
        args.each do |arg|
          paginate_model(arg)
        end
      end

      def paginate_model(model)
        pagination_class.resolve_model(model)
        pagination[model] = (pagination_class.new(self, model))
        pagination[model].refresh_action!
      end

      def pagination_class
        @pagination_class ||= Pagination::Controller::Paginator
      end

      def pagination_class=(struct)
        @pagination_class = struct
      end

      def pagination=(calls)
        @pagination = calls
      end

      def pagination
        @pagination ||= {}
      end

      # Has to return a method that takes a query as an argument
      # See pagination::Model#paginate_scope!
      def pagination_for(model, call)
        resolve_paginator_for(model).pagination = (call.respond_to?(:call) ? call : call.to_s.to_sym)
      end

      def search_for(model, call)
        resolve_paginator_for(model).search = (call.respond_to?(:call) ? call : call.to_s.to_sym)
      end

      def action_for(model, call)
        resolve_paginator_for(model).action = (call.respond_to?(:call) ? call : call.to_s.to_sym)
      end

      def response_for(model, call)
        resolve_paginator_for(model).response = (call.respond_to?(:call) ? call : call.to_s.to_sym)
      end

      def search_options_for(model, options)
        resolve_paginator_for(model).search_options = options
      end

      private

      def resolve_paginator_for(model)
        model = pagination_class.resolve_model(model)
        inst = pagination.find { |_, pag| pag.model == model }[1]

        if inst.nil?
          raise ArgumentError, "Model #{model} is not being paginated. Call #paginate_model(s) first."
        else
          return inst
        end
      end
    end
  end
end
