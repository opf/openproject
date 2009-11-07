module CodeRay
module Encoders

  load :html

  class Div < HTML

    FILE_EXTENSION = 'div.html'

    register_for :div

    DEFAULT_OPTIONS = HTML::DEFAULT_OPTIONS.merge \
      :css => :style,
      :wrap => :div

  end

end
end
