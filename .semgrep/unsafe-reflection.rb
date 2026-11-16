# frozen_string_literal: true

class UnsafeReflectionExamplesController < ApplicationController
  DEFAULT_ATTRIBUTE = :name

  def dispatch_from_params
    attribute = params[:attribute]
    # ruleid: params-to-dynamic-dispatch
    @record.public_send(attribute)
  end

  def dispatch_from_interpolation
    # ruleid: params-to-dynamic-dispatch
    @record.send("#{params[:field]}=", params[:value])
  end

  def dispatch_from_constant
    # ok: params-to-dynamic-dispatch
    @record.public_send(DEFAULT_ATTRIBUTE)
  end

  def constant_from_params
    # ruleid: params-to-constant-lookup
    params[:type].constantize.new
  end

  def constant_from_literal
    # ok: params-to-constant-lookup
    "Project".constantize
  end
end
