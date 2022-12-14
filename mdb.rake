directory(MDB_OUTPUT_PATH)

CLOBBER.include(File.join(MDB_OUTPUT_PATH, '*'))

task :directories => [MDB_OUTPUT_PATH]

namespace :mdb do
  desc 'Sets the debug tool.'
  task :hwtool, [:toolType] do |t, args|
    raise 'Please specify debug tool.' unless !args[:toolType].nil?
    @ceedling[MDB_SYM].update_config(hwtool: args[:toolType])
  end
end
