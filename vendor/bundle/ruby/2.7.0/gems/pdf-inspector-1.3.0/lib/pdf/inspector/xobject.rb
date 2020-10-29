module PDF
  class Inspector
    class XObject < Inspector
      attr_accessor :page_xobjects, :xobject_streams

      def initialize
        @page_xobjects = []
        @xobject_streams = {}
      end

      def page=(page)
        @page_xobjects << page.xobjects
        page.xobjects.each do |label, stream|
          @xobject_streams[label] = stream
        end
      end
    end
  end
end
