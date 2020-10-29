# frozen_string_literal: true

# Line wrapping happens on white space or hyphens. Soft hyphens can be used to
# indicate where words can be hyphenated. Non-breaking spaces can be used to
# display space without allowing for a break.
#
# For writing styles that do not make use of spaces, the zero width space serves
# to mark word boundaries. Zero width spaces are available only with external
# fonts.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text "Hard hyphens:\n" \
    'Slip-sliding away, slip sliding awaaaay. You know the ' \
    "nearer your destination the more you're slip-sliding away."
  move_down 20

  shy = Prawn::Text::SHY
  text "Soft hyphens:\n" \
    "Slip slid#{shy}ing away, slip slid#{shy}ing away. You know the " \
    "nearer your destinat#{shy}ion the more you're slip slid#{shy}ing away."
  move_down 20

  nbsp = Prawn::Text::NBSP
  text "Non-breaking spaces:\n" \
    "Slip#{nbsp}sliding away, slip#{nbsp}sliding awaaaay. You know the " \
    "nearer your destination the more you're slip#{nbsp}sliding away."
  move_down 20

  font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf", size: 16) do
    long_text = "No word boundaries:\n更可怕的是，"\
      '同质化竞争对手可以按照URL中后面这个ID来遍历您的DB中的内容，'\
      '写个小爬虫把你的页面上的关键信息顺次爬下来也不是什么难事，'\
      '这样的话，你就非常被动了。更可怕的是，'\
      '同质化竞争对手可以按照URL中后面这个ID来遍历您的DB中的内容，'\
      '写个小爬虫把你的页面上的关键信息顺次爬下来也不是什么难事，'\
      '这样的话，你就非常被动了。'
    text long_text
    move_down 20

    zwsp = Prawn::Text::ZWSP
    long_text = "Invisible word boundaries:\n更#{zwsp}可怕的#{zwsp}是，"\
      "#{zwsp}同质化#{zwsp}竞争#{zwsp}对#{zwsp}手#{zwsp}可以#{zwsp}按照#{zwsp}"\
      "URL#{zwsp}中#{zwsp}后面#{zwsp}这个#{zwsp}ID#{zwsp}来#{zwsp}遍历#{zwsp}"\
      "您的#{zwsp}DB#{zwsp}中的#{zwsp}内容，#{zwsp}写个#{zwsp}小爬虫#{zwsp}把"\
      "#{zwsp}你的#{zwsp}页面#{zwsp}上的#{zwsp}关#{zwsp}键#{zwsp}信#{zwsp}息顺"\
      "#{zwsp}次#{zwsp}爬#{zwsp}下来#{zwsp}也#{zwsp}不是#{zwsp}什么#{zwsp}"\
      "难事，#{zwsp}这样的话，#{zwsp}你#{zwsp}就#{zwsp}非常#{zwsp}被动了。"\
      "#{zwsp}更#{zwsp}可怕的#{zwsp}是，#{zwsp}同质化#{zwsp}竞争#{zwsp}对"\
      "#{zwsp}手#{zwsp}可以#{zwsp}按照#{zwsp}URL#{zwsp}中#{zwsp}后面#{zwsp}"\
      "这个#{zwsp}ID#{zwsp}来#{zwsp}遍历#{zwsp}您的#{zwsp}DB#{zwsp}中的#{zwsp}"\
      "内容，#{zwsp}写个#{zwsp}小爬虫#{zwsp}把#{zwsp}你的#{zwsp}页面#{zwsp}"\
      "上的#{zwsp}关#{zwsp}键#{zwsp}信#{zwsp}息顺#{zwsp}次#{zwsp}爬#{zwsp}下来"\
      "#{zwsp}也#{zwsp}不是#{zwsp}什么#{zwsp}难事，#{zwsp}这样的话，#{zwsp}你"\
      "#{zwsp}就#{zwsp}非常#{zwsp}被动了。"
    text long_text
  end
end
