#!/usr/bin/ruby

require "pry"
require "csv"
require "fileutils"

require_relative "../src/script_params"
require_relative "../src/chem_reading"

params = ScriptParams.read!(
  {
    name:    "from",
    attr:    "input_dir",
    default: "data/processed/chems"
  },
  {
    name:    "by",
    attr:    "group_attr",
    cast:    -> (group_attr) { group_attr.downcase.to_sym }
  },
  {
    name:    "type",
    attr:    "reading_types",
    default: [:very_atypical],
    cast:    -> (raw_types) { Array(raw_types).map(&:to_sym) }
  },
  {
    name:    "output-dir",
    attr:    "root_output_dir",
    default: "data/processed"
  }
)

INPUT_DIR       = params.fetch(:input_dir)
ROOT_OUTPUT_DIR = params.fetch(:root_output_dir)
READING_TYPES   = params.fetch(:reading_types)
GROUP_ATTR      = params.fetch(:group_attr)

OUTPUT_DIR      = "#{ROOT_OUTPUT_DIR}/groupings/#{GROUP_ATTR}/#{READING_TYPES.sort.join('-')}"

class ChemDataGrouper
  def group(path)
    csv_headers, readings = readings_in(path, READING_TYPES)
    grouped_readings      = readings.group_by(&GROUP_ATTR)

    grouped_readings.each do |(_, readings_in_group)|
      store_readings(csv_headers, readings_in_group)
    end
  end

  private

  def readings_in(dir, types)
    csv_headers = nil

    readings = types.flat_map do |type|
      Dir["#{dir}/*-#{type}.csv"].flat_map do |file_name|
        csv_headers, *csv_rows = CSV.read(file_name)
        ChemReading.all_from(csv_rows)
      end
    end

    [csv_headers, readings]
  end

  def store_readings(csv_headers, readings)
    sorted_readings  = readings.sort(&method(:sort_readings))
    group_attr_value = readings.first.public_send(GROUP_ATTR)

    CSV.open("#{OUTPUT_DIR}/#{GROUP_ATTR}-#{group_attr_value}.csv", "w") do |csv_file|
      csv_file << csv_headers if csv_headers
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
ChemDataGrouper.new.group(INPUT_DIR)
