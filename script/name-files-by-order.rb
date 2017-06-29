#!/usr/bin/ruby

require "pry"
require "fileutils"

GASES_DIR = "data/processed/gas"

chem_dirs = Dir.glob("#{GASES_DIR}/*").select do |file|
  File.directory?(file) && File.basename(file) != "images"
end

chem_dirs.each do |chem_dir|
  filenames = Dir["#{chem_dir}/*.csv"].sort_by do |file|
    File.basename(file, File.extname(file)).to_i
  end

  filenames.each_with_index do |file, idx|
    extname = File.extname(file)
    File.rename(file, "#{chem_dir}/#{idx}#{extname}")
  end
end
