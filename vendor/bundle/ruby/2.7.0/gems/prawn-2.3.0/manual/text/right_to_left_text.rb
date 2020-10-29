# frozen_string_literal: true

# Prawn can be used with right-to-left text. The direction can be set
# document-wide, on particular text, or on a text-box. Setting the direction to
# <code>:rtl</code> automatically changes the default alignment to
# <code>:right</code>
#
# You can even override direction on an individual fragment. The one caveat is
# that two fragments going against the main direction cannot be placed next to
# each other without appearing in the wrong order.
#
# Writing bidirectional text that combines both left-to-right and right-to-left
# languages is easy using the <code>bidi</code> Ruby Gem and its
# <code>render_visual</code> function. See https://github.com/elad/ruby-bidi for
# instructions and an example using Prawn.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # set the direction document-wide
  self.text_direction = :rtl

  font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf", size: 16) do
    long_text = '写个小爬虫把你的页面上的关键信息顺次爬下来也不是什么难事写个'\
      '小爬虫把你的页面上的关键信息顺次爬下来也不是什么难事写个小爬虫把你的页'\
      '面上的关键信息顺次爬下来也不是什么难事写个小'
    text long_text
    move_down 20

    text 'You can override the document direction.', direction: :ltr
    move_down 20

    formatted_text [
      { text: '更可怕的是，同质化竞争对手可以按照' },
      { text: 'URL', direction: :ltr },
      { text: '中后面这个' },
      { text: 'ID', direction: :ltr },
      { text: '来遍历您的' },
      { text: 'DB', direction: :ltr },
      { text: '中的内容，写个小爬虫把你的页面上的关键信息顺次爬下来也不是什么'\
        '难事，这样的话，你就非常被动了。' }
    ]
    move_down 20

    formatted_text [
      { text: '更可怕的是，同质化竞争对手可以按照' },
      { text: 'this',  direction: :ltr },
      { text: "won't", direction: :ltr, size: 24 },
      { text: 'work',  direction: :ltr },
      { text: '中的内容，写个小爬虫把你的页面上的关键信息顺次爬下来也不是什么难事' }
    ]
  end
end
