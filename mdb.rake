directory(MDB_OUTPUT_PATH)

CLOBBER.include(File.join(MDB_OUTPUT_PATH, '*'))

task :directories => MDB_OUTPUT_PATH

namespace :mdb do
  desc 'Sets the debug tool.'
  task :hwtool, [:tool] do |t, args|
    @ceedling[MDB_SYM].set_hwtool(args[:tool])
  end
  
  desc 'Setup serial port.'
  task :serialport, [:port, :baudrate, :data_bits, :stop_bits, :parity] do |t, args|
    @ceedling[MDB_SYM].set_serialport(args.to_hash)
  end
end
