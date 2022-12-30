directory(MDB_OUTPUT_PATH)

CLOBBER.include(File.join(MDB_OUTPUT_PATH, '*'))

task :mdb_deps => [MDB_OUTPUT_PATH]

namespace :mdb do
  desc 'Sets the debug tool.'
  task :hwtool, [:tool_type] do |t, args|
    raise 'Please specify debug tool.' if args[:tool_type].nil?
    @ceedling[MDB_SYM].update_config(hwtool: args[:tool_type])
  end
  
  desc 'Setup serial port.'
  task :serialport, [:port, :baudrate, :data_bits, :stop_bits, :parity] do |t, args|
    raise 'Please specify serial port.' if args[:port].nil?
    @ceedling[MDB_SYM].update_config(serialport: args.to_hash)
  end
end
