module ChartsHelper
  def scale_x(values, data_points = 30)
    step = x_step(values, data_points)
    values.map{|n| n * step }.join(',')
  end
  
  def scale_y(values, max = nil)
    max = max || values.max
    values.map{|v| v==max ? 100 : (v.to_f/max).round(2)*100}.join(",")
  end
  
  def x_step(values, data_points = nil)
    data_points = data_points || values.length
    (100.0/(data_points-1)).round(2)
  end
  
  def x_labels(labels)
    if(x_step(labels) > 15)     # if x gridlines are more than 10 pixels apart
      labels.map{|d| d.strftime("%m/%d")}.join("|")
    else              
      alt = []
      labels.each_index do |i|
        alt << (i.modulo(2)==0 ? labels[i].strftime("%d") : '')
      end
      alt.join("|")
    end
  end
end
