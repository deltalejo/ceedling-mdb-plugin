#!/usr/bin/env ruby

require 'open3'
require 'optparse'
require 'serialport'

PARITIES = {
  :none => SerialPort::NONE,
  :even => SerialPort::EVEN,
  :odd => SerialPort::ODD
}.freeze

DEFAULT_OPTIONS = {
  :baud => 115200,
  :data_bits => 8,
  :stop_bits => 1,
  :parity => SerialPort::NONE
}.freeze

options = DEFAULT_OPTIONS.dup

OptionParser.new do |parser|
  parser.banner = "Usage: #{File.basename($0)} [options] -- mdb [mdb arguments]"
  
  parser.on('--port [PORT]', String)
  parser.on('--baud [BAUDRATE]', "Default: #{DEFAULT_OPTIONS[:baud]}", Integer)
  parser.on('--data_bits [DATA BITS]', "Default: #{DEFAULT_OPTIONS[:data_bits]}", Integer)
  parser.on('--stop_bits [STOP BITS]', "Default: #{DEFAULT_OPTIONS[:stop_bits]}", Integer)
  parser.on('--parity [PARITY]', "Default: #{DEFAULT_OPTIONS[:parity]}", PARITIES.keys) do |parity|
    options[:parity] = PARITIES[parity.to_sym]
  end
end.parse!(into: options)

mdb_args = ARGV
raise OptionParser::MissingArgument, 'mdb' if mdb_args.empty?

Open3.popen3(*mdb_args) do |mdb_in, mdb_out, mdb_err, mdb_thr|
  stdout_thr = Thread.new do
    mdb_out.each do |line|
      $stdout << line
      if line =~ /[[:alpha:]]+ you [[:alpha:]]+ to continue\?/i
        answer = (line =~ /Target device ID \(.*?\) is an invalid device ID/i)? 'no' : 'yes'
        mdb_in.puts answer
      end
    end
  end
  
  stderr_thr = Thread.new do
    mdb_err.each {|line| $stderr << line}
  end
  
  if port = options.delete(:port)
    options.transform_keys! {|key| key.to_s}
    serial_thr = Thread.new do
      SerialPort.open(port, options) do |sp|
        sp.each {|line| $stdout << line}
      end
    end
  end
  
  mdb_thr.join
  stdout_thr.join
  stderr_thr.join
  serial_thr.terminate.join unless serial_thr.nil?
end
