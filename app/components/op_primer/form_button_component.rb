# frozen_string_literal: true

class OpPrimer::FormButtonComponent < Primer::Component
  def initialize(
    url:,
    method:,
    form_arguments: {},
    button_component: Primer::Beta::Button,
    button_arguments: {},
    **system_arguments
  )
    @url = url
    @method = method
    @form_arguments = form_arguments
    @form_arguments = form_arguments

    @button_component = button_component
    @button_arguments = button_arguments

    @system_arguments = system_arguments

    super()
  end
end
