def readings_from(stats, rows_by_chem, readings_type: :normal)
  rows_by_chem.each_with_object({}) do |(chem, rows), result|
    rows         = rows.public_send(readings_type) unless rows.is_a?(Array)
    readings     = rows.group_by { |row| bad_reading?(stats, chem, row) }
    result[chem] = Readings.new(readings[false], readings[true])
  end
end

def store_readings(readings_by_chem)
  readings_by_chem.each do |(chem, readings)|
    CSV.open("#{chem.downcase}-good.csv", "w") do |csv|
      readings.normal.sort { |a, b| sorting(a, b) }.each { |row| csv << row }
    end

    CSV.open("#{chem.downcase}-bad.csv", "a") do |csv|
      readings.bad_readings.sort { |a, b| sorting(a, b) }.each { |row| csv << row }
    end
  end
end

Stats = Struct.new("Stats", :avg, :stddev)

Readings = Struct.new("Readings", :normal, :bad_readings)

def avg(values)
  return 0.0 if values.empty?
  values.sum / values.length.to_f
end

def stddev(values, average)
  return 0.0 if values.length <= 1
  sum = values.sum { |value| (value - average)**2 }
  # sample correction for stddev
  Math.sqrt(sum / values.length.to_f)
end

def stats_for(rows_by_chem, readings_type: :normal)
  rows_by_chem.each_with_object({}) do |(chem, rows), results|
    rows          = rows.public_send(readings_type) unless rows.is_a?(Array)
    readings      = rows.map { |row| row.last.to_f }
    average       = avg(readings)
    results[chem] = Stats.new(average, stddev(readings, average))
  end
end

def bad_reading?(stats, chem, row)
  (row.last.to_f - stats[chem].avg).abs >= stats[chem].stddev
end

Reading = Struct.new("Reading", :chem, :raw_monitor, :raw_date_time, :raw_reading) do
  def date_time
    parse_date(raw_date_time)
  end

  def monitor
    raw_monitor.to_i
  end

  def reading
    raw_reading.to_f
  end

  def parse_date(str, base_year = 2000)
    date_str, time_str        = str.split(" ")
    month, day, relative_year = date_str.split("/").map(&:to_i)

    base_year -= 100 if relative_year > DateTime.now.year.to_s[-2..-1].to_i
    year          = base_year + relative_year
    hour, minutes = time_str.split(":").map(&:to_i)
    DateTime.new(year, month, day, hour, minutes)
  end
end

def sorting(row_a, row_b)
  reading_a, reading_b = [row_a, row_b].map { |row| Reading.new(*row) }
  [reading_a.monitor, reading_a.date_time] <=> [reading_b.monitor, reading_b.date_time]
end
