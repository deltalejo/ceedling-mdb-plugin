require 'ceedling/plugin'
require 'mdb_defaults'

MDB_ROOT_NAME       = 'mdb'.freeze
MDB_SYM             = MDB_ROOT_NAME.to_sym

MDB_CMD_FILE_SUFFIX = '_cmd.txt'.freeze

def mdb_form_cmd_filepath(filepath)
  return ceedling_form_filepath(MDB_OUTPUT_PATH, filepath, '') + MDB_CMD_FILE_SUFFIX
end

class Mdb < Plugin
  def setup
    project_config = @ceedling[:setupinator].config_hash
    mdb_defaults = {
      :tools => {
        :mdb => DEFAULT_MDB_TOOL
      }
    }
    @ceedling[:configurator_builder].populate_defaults(project_config, mdb_defaults)
    
    @config = project_config[MDB_SYM]
    @tool = project_config[:tools][MDB_SYM]
    
    raise unless @ceedling[:configurator_validator].exists?(@config, :device)
    raise unless @ceedling[:configurator_validator].exists?(@config, :hwtool)
    
    [:device, :hwtool].each do |key|
      if (@config[key] =~ RUBY_STRING_REPLACEMENT_PATTERN)
        @config[key].replace(@ceedling[:system_wrapper].module_eval(@config[key]))
      end
    end
    
    mdb_config = {
      :mdb => {
        :output_path => File.join(PROJECT_BUILD_ROOT, MDB_ROOT_NAME)
      },
      :tools => {
        :mdb => @tool
      }
    }
    mdb_config[:tools][:test_fixture] = @tool if @config[:test_fixture]
    @ceedling[:configurator].build_supplement(project_config, mdb_config)
  end
  
  def update_config(**kwargs)
    @config.merge!(kwargs)
    project_config = @ceedling[:setupinator].config_hash
    @ceedling[:configurator].build_supplement(project_config, {:mdb => @config})
  end
  
  def form_cmd_filepath(filepath)
    return File.join(MDB_OUTPUT_PATH, File.basename(filepath, '.*') + MDB_CMD_FILE_SUFFIX)
  end
  
  def pre_test(test)
    return unless @config[:test_fixture]
    
    Rake.application[MDB_ROOT_NAME + '_deps'].invoke
    write_command_file(test)
  end
  
  private
  
  def write_command_file(test)
    exec_file = @ceedling[:file_path_utils].form_test_executable_filepath(test)
    cmd_file = form_cmd_filepath(test)
    device = @config[:device]
    hwtool = @config[:hwtool]
    tool_properties = @config[:tools_properties].fetch(hwtool.to_sym, {})
    
    File.open(cmd_file, 'w') do |f|
      f.puts("device #{device}")
      tool_properties.each do |key, val|
        f.puts "set #{key} #{val}"
      end
      f.puts("hwtool #{hwtool}")
      f.puts("program #{exec_file}")
      f.puts('run')
      f.puts('wait')
      f.puts('quit')
    end
  end
end
