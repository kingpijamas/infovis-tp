#!/usr/bin/ruby

require "pry"
require "csv"
require "fileutils"

require_relative "wind_reading"

INPUT_FILE  = ARGV.shift
OUTPUT_DIR  = "data/processed"
OUTPUT_FILE = "winds.csv"

class WindRefiner
  WIND_READING_ATTRS_COUNT = WindReading.members.count - 1

  def refine(file_path)
    csv_headers, *csv_rows = CSV.read(file_path).each_with_object([]) do |csv_row, result|
      relevant_values = csv_row[0..WIND_READING_ATTRS_COUNT]
      result << relevant_values if relevant_values.any?
    end

    readings = csv_rows.map { |row| WindReading.new(*row) }

    store_readings(csv_headers, readings)
  end

  private

  def store_readings(headers, readings)
    sorted_readings = readings.sort

    CSV.open("#{OUTPUT_DIR}/#{OUTPUT_FILE}", "w") do |csv_file|
      csv_file << headers
      sorted_readings.each { |reading| csv_file << reading.to_a }
    end
  end
end

FileUtils.mkdir_p OUTPUT_DIR
WindRefiner.new.refine(INPUT_FILE)
