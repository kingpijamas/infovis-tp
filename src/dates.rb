module Dates
  def self.date_from(raw_date_time, base_year = 2000)
    date_str, time_str        = raw_date_time.split(" ")
    month, day, relative_year = date_str.split("/").map(&:to_i)

    base_year -= 100 if relative_year > DateTime.now.year.to_s[-2..-1].to_i
    year          = base_year + relative_year
    hour, minutes = time_str.split(":").map(&:to_i)
    DateTime.new(year, month, day, hour, minutes)
  end

  def self.seconds_between(*time_range)
    ((time_range.last - time_range.first) * 24 * 60 * 60).to_i
  end
end
