require 'ceedling/plugin'
require 'mdb_defaults'

MDB_ROOT_NAME       = 'mdb'.freeze
MDB_SYM             = MDB_ROOT_NAME.to_sym
MDB_FIXTURE_SYM     = (MDB_ROOT_NAME + '_fixture').to_sym

MDB_FIXTURE_SCRIPT  = 'mdb_fixture.rb'.freeze
MDB_FIXTURE_PATH    = File.expand_path(File.join(File.dirname(__FILE__), '..', 'bin')).freeze
MDB_FIXTURE         = File.join(MDB_FIXTURE_PATH, MDB_FIXTURE_SCRIPT).freeze
MDB_CMD_FILE_SUFFIX = '_cmd.txt'.freeze

class Mdb < Plugin
  def setup
    project_config = @ceedling[:setupinator].config_hash
    mdb_defaults = {
      :tools => {
        :mdb => DEFAULT_MDB_TOOL,
        :mdb_fixture => DEFAULT_MDB_FIXTURE_TOOL
      }
    }
    @ceedling[:configurator_builder].populate_defaults(project_config, mdb_defaults)
    
    @config = project_config[MDB_SYM]
    @tool = project_config[:tools][MDB_SYM]
    @fixture = project_config[:tools][MDB_FIXTURE_SYM]
    
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
        :mdb => @tool,
        :mdb_fixture => @fixture
      }
    }
    mdb_config[:tools][:test_fixture] = @fixture if @config[:test_fixture]
    @ceedling[:configurator].build_supplement(project_config, mdb_config)
  end
  
  def update_config(**kwargs)
    @config.deep_merge!(kwargs)
    project_config = @ceedling[:setupinator].config_hash
    @ceedling[:configurator].build_supplement(project_config, {:mdb => @config})
  end
  
  def form_cmd_filepath(filepath)
    return File.join(MDB_OUTPUT_PATH, File.basename(filepath, '.*') + MDB_CMD_FILE_SUFFIX)
  end
  
  def pre_test_fixture_execute(arg_hash)
    return unless @config[:test_fixture]
    
    Rake.application[MDB_ROOT_NAME + '_deps'].invoke
    write_command_file(arg_hash[:executable])
    
    @fixture_arguments = @fixture[:arguments]
    @fixture[:arguments] = Array.new(@fixture[:arguments])
    
    if @config[:hwtool] != 'sim'
      raise 'Please specify serial port.' unless @config[:serialport][:port]
      
      serialport_params = {
        :port => @config[:serialport][:port],
        :baud => @config[:serialport][:baudrate],
        :data_bits => @config[:serialport][:data_bits],
        :stop_bits => @config[:serialport][:stop_bits],
        :parity => @config[:serialport][:parity]
      }
      serialport_params.each do |key, val|
        @fixture[:arguments] << "--#{key} #{val}"
      end
    end
    
    mdb_command = @ceedling[:tool_executor].build_command_line(
      @tool, [], form_cmd_filepath(arg_hash[:executable])
    )
    @fixture[:arguments] << mdb_command[:line]
    
    @ceedling[:streaminator].stdout_puts("MDB command: #{mdb_command}", Verbosity::DEBUG)
    @ceedling[:streaminator].stdout_puts("MDB fixture: #{@fixture}", Verbosity::DEBUG)
  end
  
  def post_test_fixture_execute(arg_hash)
    return unless @config[:test_fixture]
    
    @fixture[:arguments] = @fixture_arguments
  end
  
  private
  
  def write_command_file(exec)
    cmd_file = form_cmd_filepath(exec)
    @ceedling[:streaminator].stdout_puts("Creating #{cmd_file}...", Verbosity::NORMAL)
    
    device = @config[:device]
    hwtool = @config[:hwtool]
    tool_properties = @config[:hwtools_properties].fetch(hwtool.to_sym, {})
    
    File.open(cmd_file, 'w') do |f|
      f.puts("device #{device}")
      tool_properties.each do |key, val|
        f.puts "set #{key} #{val}"
      end
      f.puts("hwtool #{hwtool}")
      f.puts("program #{exec}")
      f.puts('run')
      f.puts('wait')
      f.puts('quit')
    end
  end
end
