#!/usr/bin/env ruby

require 'open3'
require 'optparse'
require 'serialport'

PARITIES = {
  :none => SerialPort::NONE,
  :even => SerialPort::EVEN,
  :odd => SerialPort::ODD
}

options = {
  :baud => 115200,
  :data_bits => 8,
  :stop_bits => 1,
  :parity => SerialPort::NONE
}

serialport_args = ARGV.take_while {|item| item.strip != "--"}
mdb_args = ARGV[(serialport_args.length + 1)..-1]

OptionParser.new do |parser|
  parser.banner = "Usage: #{File.basename($0)} [options] -- <mdb> [mdb arguments]"
  
  parser.on('--port [PORT]', String)
  parser.on('--baud [BAUDRATE]', Integer)
  parser.on('--data_bits [DATA BITS]', Integer)
  parser.on('--stop_bits [STOP BITS]', Integer)
  parser.on('--parity [PARITY]') do |parity|
    options[:parity] = PARITIES[parity.to_sym]
  end
end.parse!(serialport_args, into: options)

raise OptionParser::MissingArgument, 'mdb' if mdb_args.empty?

Open3.popen3(*mdb_args) do |mdb_in, mdb_out, mdb_err, mdb_thr|
  Thread.new do
    until mdb_out.eof?
      line = mdb_out.gets
      $stdout << line
      if line =~ /Do you .+ to continue\?/
        mdb_in.puts 'yes'
      end
    end
  end
  
  Thread.new do
    until mdb_err.eof?
      $stderr << mdb_err.gets
    end
  end
  
  if (port = options.delete(:port))
    options.transform_keys! {|key| key.to_s}
    serial_thr = Thread.new do
      SerialPort.open(port, options) do |sp|
        $stdout << sp.gets while true
      end
    end
  end
  
  mdb_thr.join
  serial_thr.kill unless serial_thr.nil?
end
