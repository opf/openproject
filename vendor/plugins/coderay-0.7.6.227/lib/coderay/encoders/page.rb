module CodeRay
module Encoders

  load :html

  class Page < HTML

    FILE_EXTENSION = 'html'

    register_for :page

    DEFAULT_OPTIONS = HTML::DEFAULT_OPTIONS.merge({
      :css => :class,
      :wrap => :page,
      :line_numbers => :table
    })

  end

end
end
