require 'ceedling/constants'
require 'ceedling/exceptions'
require 'ceedling/plugin'

MDB_ROOT_NAME       = 'mdb'.freeze
MDB_SYM             = MDB_ROOT_NAME.to_sym

MDB_OUTPUT_PATH     = File.join(PROJECT_BUILD_ROOT, MDB_ROOT_NAME)
MDB_FIXTURE_PATH    = File.expand_path(File.join(File.dirname(__FILE__), '..', 'bin')).freeze
MDB_FIXTURE_SCRIPT  = 'mdb_fixture.rb'.freeze

MDB_CMD_FILE_SUFFIX = 'cmd'.freeze
MDB_CMD_FILE_EXT    = '.txt'.freeze

MDB_LOG_FILE_SUFFIX = 'log'.freeze
MDB_LOG_FILE_EXT    = '.xml'.freeze

class Mdb < Plugin
  def setup
    @configurator_validator = @ceedling[:configurator_validator]
    @loginator = @ceedling[:loginator]
    @reportinator = @ceedling[:reportinator]
    @setupinator = @ceedling[:setupinator]
    @system_wrapper = @ceedling[:system_wrapper]
    @tool_executor = @ceedling[:tool_executor]
    
    project_config = @setupinator.config_hash
    
    unless @configurator_validator.exists?(project_config, MDB_SYM)
      walk = @reportinator.generate_config_walk([MDB_SYM])
      error = "MDB plugin is enabled but missing the required configuration block `#{walk}`"
      raise CeedlingException.new(error)
    end
    
    @config = project_config[MDB_SYM]
    
    validate_config()
    evaluate_config()
  end
  
  def set_hwtool(hwtool)
    if hwtool.nil? || hwtool.empty?
      error = "MDB debug tool must be given"
      raise CeedlingException.new(error)
    end
    
    @config[:hwtool] = hwtool
  end
  
  def set_serialport(params)
    if params[:port].nil? || params[:port].empty?
      error = "MDB serial port must be given"
      raise CeedlingException.new(error)
    end
    
    @config[:serialport].merge!(params)
  end
  
  def pre_test(test)
    validate_late_config()
  end
  
  def pre_test_fixture_execute(arg_hash)
    executable = arg_hash[:executable]
    
    write_command_file(executable)
    
    arg_hash[:tool] = TOOLS_MDB_FIXTURE.clone
    arg_hash[:tool][:arguments] = opts_builder_fixture(executable)
  end
  
  private
  
  def validate_config()
    unless @config.is_a?(Hash)
      walk = @reportinator.generate_config_walk([MDB_SYM])
      error = "Expected configuration #{walk} to be a Hash but found #{@config.class}"
      raise CeedlingException.new(error)
    end
    
    validations = []
    validations << @configurator_validator.exists?(@config, :device)
    validations << @configurator_validator.exists?(@config, :hwtool)
    
    unless validations.all?
      error = "MDB plugin configuration failed validation"
      raise CeedlingException.new(error)
    end
  end
  
  def validate_late_config()
    validations = []
    validations << @configurator_validator.exists?(@config, :hwtool)
    if @config[:hwtool] != "sim"
      validations << @configurator_validator.exists?(@config, :serialport, :port)
    end
    
    unless validations.all?
      error = "MDB plugin configuration failed validation"
      raise CeedlingException.new(error)
    end
  end
  
  def traverse_config_eval_strings(config)
    case config
      when String
        if (config =~ PATTERNS::RUBY_STRING_REPLACEMENT)
          config.replace(@system_wrapper.module_eval(config))
        end
      when Array
        if config.all? {|item| item.is_a?(String)}
          config.each do |item|
            if (item =~ PATTERNS::RUBY_STRING_REPLACEMENT)
              item.replace(@system_wrapper.module_eval(item))
            end
          end
        end
      when Hash
        config.each_value {|value| traverse_config_eval_strings(value)}
      end
  end
  
  def evaluate_config()
    @config.each_value do |item|
      traverse_config_eval_strings(item)
    end
  end
  
  def form_cmd_filepath(filepath)
    return File.join(
      MDB_OUTPUT_PATH,
      [File.basename(filepath, '.*'), MDB_CMD_FILE_SUFFIX].join('_')
    ).ext(MDB_CMD_FILE_EXT)
  end
  
  def form_log_filename(hwtool)
    return [MDB_ROOT_NAME, hwtool, MDB_LOG_FILE_SUFFIX].join("_").ext(MDB_LOG_FILE_EXT)
  end
  
  def opts_builder_mdb()
    opts = [
      "--log-dir #{PROJECT_LOG_PATH}",
      "--file-name #{form_log_filename(@config[:hwtool])}"
    ]
    
    return opts
  end
  
  def opts_builder_serialport()
    serialport_params = {
      :port => @config[:serialport][:port],
      :baud => @config[:serialport][:baudrate],
      :data_bits => @config[:serialport][:data_bits],
      :stop_bits => @config[:serialport][:stop_bits],
      :parity => @config[:serialport][:parity]
    }
    
    opts = serialport_params.map do |key, val|
      "--#{key} #{val}"
    end
    
    return opts
  end
  
  def opts_builder_fixture(executable)
    mdb_fixture_filepath = File.join(MDB_FIXTURE_PATH, MDB_FIXTURE_SCRIPT)
    opts = [mdb_fixture_filepath]
    
    if @config[:hwtool] != 'sim'
      opts += opts_builder_serialport()
    end
    
    mdb_command = @tool_executor.build_command_line(
      TOOLS_MDB,
      opts_builder_mdb(),
      form_cmd_filepath(executable)
    )
    
    opts << '--' << mdb_command[:line]
    
    return opts
  end
  
  def write_command_file(filename)
    cmd_file = form_cmd_filepath(filename)
    @loginator.log("Creating #{File.basename(cmd_file)}...")
    
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
      f.puts("program #{filename}")
      breakpoints&.each do |breakpoint|
        f.puts("break #{breakpoint}")
      end
      f.puts('run')
      f.puts('wait' + timeout)
      f.puts('quit')
    end
  end
end
