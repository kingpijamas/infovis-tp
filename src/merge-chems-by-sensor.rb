#!/usr/bin/ruby

require "pry"

require_relative "chem_reading"
require "csv"
require "fileutils"

INPUT_DIR  = ARGV.shift || "data/processed/chems"
OUTPUT_DIR = "data/processed/monitor-errors"

class ChemDataMerger
  def merge(path)
    csv_headers, errored_readings = readings_in(path, :errored)
    errored_readings_by_monitor   = errored_readings.group_by(&:monitor)

    errored_readings_by_monitor.each do |(monitor, errored_readings_for_monitor)|
      store_monitor_readings(csv_headers, errored_readings_for_monitor)
    end
  end

  private

  def readings_in(dir, type)
    csv_headers = []

    readings = Dir["#{dir}/*-#{type}.csv"].flat_map do |file_name|
      csv_headers, *csv_rows = CSV.read(file_name)
      csv_rows.map { |row| ChemReading.new(*row) }
    end

    [csv_headers, readings]
  end

  def store_monitor_readings(csv_headers, monitor_readings)
    sorted_readings = monitor_readings.sort(&method(:sort_readings))

    CSV.open("#{OUTPUT_DIR}/monitor-#{monitor_readings.first.monitor}.csv", "w") do |csv_file|
      csv_file << csv_headers
      sorted_readings.each { |reading| csv_file << reading.to_a }
    end
  end

  def sort_readings(reading_a, reading_b)
    comp = reading_a.chemical <=> reading_b.chemical
    return comp if comp != 0

    reading_a <=> reading_b
  end
end

FileUtils.mkdir_p OUTPUT_DIR
ChemDataMerger.new.merge(INPUT_DIR)
