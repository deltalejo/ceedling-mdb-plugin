require 'ceedling/plugin'

MDB_ROOT_NAME       = 'mdb'.freeze
MDB_SYM             = MDB_ROOT_NAME.to_sym
MDB_FIXTURE_SYM     = (MDB_ROOT_NAME + '_fixture').to_sym

MDB_OUTPUT_PATH     = File.join(PROJECT_BUILD_ROOT, MDB_ROOT_NAME)
MDB_FIXTURE_PATH    = File.expand_path(File.join(File.dirname(__FILE__), '..', 'bin')).freeze
MDB_FIXTURE_SCRIPT  = 'mdb_fixture.rb'.freeze
MDB_FIXTURE         = File.join(MDB_FIXTURE_PATH, MDB_FIXTURE_SCRIPT).freeze

MDB_CMD_FILE_SUFFIX = 'cmd'.freeze
MDB_CMD_FILE_EXT    = '.txt'.freeze

MDB_LOG_FILE_SUFFIX = 'log'.freeze
MDB_LOG_FILE_EXT    = '.xml'.freeze

class Mdb < Plugin
  def setup
    @project_config = @ceedling[:setupinator].config_hash
    
    @config = @project_config[MDB_SYM]
    @tool = @project_config[:tools][MDB_SYM]
    @fixture = @project_config[:tools][MDB_FIXTURE_SYM]
    
    raise unless @ceedling[:configurator_validator].exists?(@config, :device)
    raise unless @ceedling[:configurator_validator].exists?(@config, :hwtool)
    
    [:device, :hwtool].each do |key|
      if @config[key] =~ RUBY_STRING_REPLACEMENT_PATTERN
        @config[key].replace(@ceedling[:system_wrapper].module_eval(@config[key]))
      end
    end
    
    mdb_config = {
      :tools => {
        :mdb => @tool,
        :mdb_fixture => @fixture
      }
    }
    mdb_config[:tools][:test_fixture] = @fixture if @config[:test_fixture]
    @ceedling[:configurator].build_supplement(@project_config, mdb_config)
  end
  
  def update_config(**kwargs)
    @config.deep_merge!(kwargs)
    @ceedling[:configurator].build_supplement(@project_config, {:mdb => @config})
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
      @tool,
      [
        "--file-name #{form_log_filename(@config[:hwtool])}",
        "--log-dir #{PROJECT_LOG_PATH}"
      ],
      form_cmd_filepath(arg_hash[:executable])
    )
    @fixture[:arguments] << '--' << mdb_command[:line]
    
    @ceedling[:loginator].log("MDB command: #{mdb_command}", Verbosity::DEBUG)
    @ceedling[:loginator].log("MDB fixture: #{@fixture}", Verbosity::DEBUG)
  end
  
  def post_test_fixture_execute(arg_hash)
    return unless @config[:test_fixture]
    
    @fixture[:arguments] = @fixture_arguments
  end
  
  private
  
  def form_cmd_filepath(filepath)
    return File.join(
      MDB_OUTPUT_PATH,
      [File.basename(filepath, '.*'), MDB_CMD_FILE_SUFFIX].join('_')
    ).ext(MDB_CMD_FILE_EXT)
  end
  
  def form_log_filename(hwtool)
    return [MDB_ROOT_NAME, hwtool, MDB_LOG_FILE_SUFFIX].join("_").ext(MDB_LOG_FILE_EXT)
  end
  
  def write_command_file(exec)
    cmd_file = form_cmd_filepath(exec)
    @ceedling[:loginator].log("Creating #{File.basename(cmd_file)}...", Verbosity::NORMAL)
    
    device = @config[:device]
    hwtool = @config[:hwtool]
    tool_properties = @config[:tools].fetch(hwtool.to_sym, {})
    breakpoints = @config[:breakpoints]
    timeout = @config[:timeout].nil? ? '' : " #{@config[:timeout]}"
    
    File.open(cmd_file, 'w') do |f|
      f.puts("device #{device}")
      tool_properties&.each do |key, val|
        f.puts "set #{key} #{val}"
      end
      f.puts("hwtool #{hwtool}")
      f.puts("program #{exec}")
      breakpoints&.each do |breakpoint|
        f.puts("break #{breakpoint}")
      end
      f.puts('run')
      f.puts('wait' + timeout)
      f.puts('quit')
    end
  end
end
