DEFAULT_MDB_TOOL = {
  :executable => (ENV['MDB'].nil? ? FilePathUtils.os_executable_ext('mdb') : ENV['MDB'].split[0]).freeze,
  :name => 'default_mdb'.freeze,
  :stderr_redirect => StdErrRedirect::NONE.freeze,
  :background_exec => BackgroundExec::NONE.freeze,
  :optional => false.freeze,
  :arguments => [
    '#{mdb_form_cmd_filepath("${1}")}'
  ].freeze
}
