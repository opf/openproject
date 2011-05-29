module Redmine
  module Views
    module MyPage
      module Block
        def self.additional_blocks
          @@additional_blocks ||= Dir.glob("#{RAILS_ROOT}/vendor/plugins/*/app/views/my/blocks/_*.{rhtml,erb}").inject({}) do |h,file|
            name = File.basename(file).split('.').first.gsub(/^_/, '')
            h[name] = name.to_sym
            h
          end
        end
      end
    end
  end
end
