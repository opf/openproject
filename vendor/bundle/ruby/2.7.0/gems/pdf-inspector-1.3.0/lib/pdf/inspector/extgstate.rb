module PDF
  class Inspector
    class ExtGState < Inspector
      attr_accessor :extgstates

      def initialize
        @extgstates = []
      end

      def page=(page)
        page.graphic_states.each do |_label, stream|
          @extgstates << {
            opacity: stream[:ca],
            stroke_opacity: stream[:CA],
            soft_mask: stream[:SMask],
            blend_mode: stream[:BM]
          }
        end
      end
    end
  end
end
