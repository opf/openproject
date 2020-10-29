require "temple"
require "erbse/parser"

module Erbse
  class BlockFilter < Temple::Filter
    # Highly inspired by https://github.com/slim-template/slim/blob/master/lib/slim/controls.rb#on_slim_output
    def on_erb_block(code, content_ast)
      # this is for <%= do %>
      outter_i = unique_name
      inner_i  = unique_name

      # this still needs the Temple::Filters::ControlFlow run-through.
      [:multi,
        [:block, "#{outter_i} = #{code}",
          [:capture, inner_i, compile(content_ast)]
        ],
        [:dynamic, outter_i] # return the outter buffer. # DISCUSS: why do we need that, again?
      ]
    end

    # assign all code in the block to new local output buffer without outputting it.
    # handles <%@ do %>
    def on_capture_block(code, content_ast)
      [:multi,
        [:block, code, # var = capture do
          [:capture, unique_name, compile(content_ast)]
        ]
      ]
    end
  end

  class Engine < Temple::Engine
    use Parser
    use BlockFilter

    # filter :MultiFlattener
    # filter :StaticMerger
    # filter :DynamicInliner
    filter :ControlFlow

    generator :ArrayBuffer
  end
  # DISCUSS: can we add more optimizers?
end

