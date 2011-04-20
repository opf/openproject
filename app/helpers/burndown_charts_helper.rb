module BurndownChartsHelper
  def yaxis_labels(burndown)
    max = [burndown.max[:hours], burndown.max[:points]].max

    labels = []

    mvalue = (max / 25) + 1

    (0..mvalue).each do |i|
      labels << "[#{i*25}, #{i*25}]"
    end

    labels << "[#{(mvalue) * 25}, '<span class=\"axislabel\">#{l('backlogs.hours')}/<br>#{l('backlogs.points')}</span>']"

    labels.join(', ')
  end

  def xaxis_labels(burndown)
    burndown.days.enum_for(:each_with_index).collect{|d,i| "[#{i+1}, '#{escape_javascript(::I18n.t('date.abbr_day_names')[d.wday % 7])}']"}.join(',') +
    ", [#{burndown.days.length + 1}, '<span class=\"axislabel\">#{I18n.t('backlogs.date')}</span>']"
  end

  def dataseries(burndown)
    burndown.series.collect{|s| "#{s.first.to_s}: {label: '#{l('backlogs.' + s.first.to_s)}', data: [#{s.last.enum_for(:each_with_index).collect{|s, i| "[#{i+1}, #{s}] "}.join(', ')}]} "}
  end
end