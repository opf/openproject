module Redmine
  module SyntaxHighlighting
    
    class << self
      attr_reader :highlighter
      delegate :highlight_by_filename, :highlight_by_language, :to => :highlighter
      
      def highlighter=(name)
        if name.is_a?(Module)
          @highlighter = name
        else
          @highlighter = const_get(name)
        end
      end
    end
    
    module CodeRay
      require 'coderay'
      require 'coderay/helpers/file_type'
      
      class << self
        # Highlights +text+ as the content of +filename+
        # Should not return line numbers nor outer pre tag
        def highlight_by_filename(text, filename)
          language = ::CodeRay::FileType[filename]
          language ? ::CodeRay.scan(text, language).html : ERB::Util.h(text)
        end
        
        # Highlights +text+ using +language+ syntax
        # Should not return outer pre tag
        def highlight_by_language(text, language)
          ::CodeRay.scan(text, language).html(:line_numbers => :inline, :wrap => :span)
        end
      end
    end
  end
  
  SyntaxHighlighting.highlighter = 'CodeRay'
end
