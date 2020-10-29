# NOTE:
#  Make a JSON Resource Descriptor (JRD) gem as separate one and use it as superclass?

module WebFinger
  class Response < ActiveSupport::HashWithIndifferentAccess
    [:subject, :aliases, :properties, :links].each do |method|
      define_method method do
        self[method]
      end
    end

    def link_for(rel)
      links.detect do |link|
        link[:rel] == rel
      end
    end
  end
end