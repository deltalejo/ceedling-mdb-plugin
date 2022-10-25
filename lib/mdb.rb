require 'ceedling/plugin'

MDB_ROOT_NAME   = 'mdb'.freeze
MDB_SYM         = MDB_ROOT_NAME.to_sym
MDB_OUTPUT_PATH = File.join(PROJECT_BUILD_ROOT, MDB_ROOT_NAME)

class Mdb < Plugin
  def setup
    @config = @ceedling[:setupinator].config_hash[MDB_SYM]
    
    raise unless @ceedling[:configurator_validator].exists?(@config, :executable)
    raise unless @ceedling[:configurator_validator].exists?(@config, :device)
    raise unless @ceedling[:configurator_validator].exists?(@config, :hwtool)
    
    if (@config[:executable] =~ RUBY_STRING_REPLACEMENT_PATTERN)
      @config[:executable].replace(@ceedling[:system_wrapper].module_eval(@config[:executable]))
    end
    if (@config[:device] =~ RUBY_STRING_REPLACEMENT_PATTERN)
      @config[:device].replace(@ceedling[:system_wrapper].module_eval(@config[:device]))
    end
    if (@config[:hwtool] =~ RUBY_STRING_REPLACEMENT_PATTERN)
      @config[:hwtool].replace(@ceedling[:system_wrapper].module_eval(@config[:hwtool]))
    end
    
    update_config(executable: @config[:executable], device: @config[:device], hwtool: @config[:hwtool])
  end
  
  def update_config(**kwargs)
    @config.merge!(kwargs)
    config_hash = @ceedling[:configurator_builder].flattenify({MDB_SYM => @config})
    @ceedling[:configurator].replace_flattened_config(config_hash)
  end
  
  def form_cmd_filepath(filepath)
    return File.join(MDB_OUTPUT_PATH, File.basename(filepath, '.*') + '_cmd.txt')
  end
  
  def form_stdout_filepath(filepath)
    return File.join(MDB_OUTPUT_PATH, File.basename(filepath, '.*') + '_stdout.txt')
  end
  
  def form_stderr_filepath(filepath)
    return File.join(MDB_OUTPUT_PATH, File.basename(filepath, '.*') + '_stderr.txt')
  end
  
  def form_serialout_filepath(filepath)
    return File.join(MDB_OUTPUT_PATH, File.basename(filepath, '.*') + '_serialout.txt')
  end
  
  def pre_test_fixture_execute(arg_hash)
    executable = arg_hash[:executable]
    
    cmd_file = form_cmd_filepath(executable)
    stdout_file = form_stdout_filepath(executable)
    stderr_file = form_stderr_filepath(executable)
    serialout_file = form_serialout_filepath(executable)
    
    write_command_file(executable)
    File.delete(serialout_file) if File.exists?(serialout_file)
    
    arg_hash[:tool] = {
      :executable => MDB_EXECUTABLE,
      :arguments => [cmd_file, ">#{stdout_file}", "&& cat #{serialout_file}"],
      :stderr_redirect => :auto
    }
  end
  
  private
  
  def write_command_file(executable)
    cmd_file = form_cmd_filepath(executable)
    serialout_file = form_serialout_filepath(executable)
    tool_options_const = "#{MDB_ROOT_NAME}_#{MDB_HWTOOL}_options".upcase
    
    options = {
      'uart1io.output' => 'file',
      'uart1io.uartioenabled' => true,
      'uart1io.outputfile' => "#{serialout_file}"
    }
    options.merge!(Object.const_get(tool_options_const)) if Object.const_defined?(tool_options_const)
    options.merge!(MDB_OPTIONS)
    
    File.open(cmd_file, 'w') do |f|
      f.puts("device #{MDB_DEVICE}")
      f.puts("hwtool #{MDB_HWTOOL}")
      options.each do |key, val|
        f.puts "set #{key} #{val}"
      end
      f.puts("program #{executable}")
      f.puts('run')
      f.puts('wait')
      f.puts('quit')
    end
  end
end
