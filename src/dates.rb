module Dates
  class << self
    def date_from(raw_date_time, base_year = 2000)
      date_str, time_str        = raw_date_time.split(" ")
      month, day, relative_year = date_str.split("/").map(&:to_i)

      base_year -= 100 if relative_year > DateTime.now.year.to_s[-2..-1].to_i
      year          = base_year + relative_year
      hour, minutes = time_str.split(":").map(&:to_i)
      DateTime.new(year, month, day, hour, minutes)
    end

    def format(date_time, base_year = 2000)
      year       = date_time.year - base_year
      minute_str = date_time.minute < 10 ? "0#{date_time.minute}" : date_time.minute.to_s
      "#{date_time.month}/#{date_time.day}/#{year} #{date_time.hour}:#{minute_str}"
    end

    def seconds_between(*times)
      ((times.max - times.min) * 24 * 60 * 60).to_i
    end

    def add_seconds(time, offset)
      time + Rational(offset, 86400)
    end
  end
end
