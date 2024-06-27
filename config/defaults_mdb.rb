DEFAULT_MDB_TOOL = {
  :executable => (ENV['MDB'].nil? ? 'mdb'.ext(SystemWrapper.windows? ? '.bat' : '') : ENV['MDB'].split[0]).freeze,
  :name => 'default_mdb'.freeze,
  :stderr_redirect => StdErrRedirect::NONE.freeze,
  :optional => false.freeze,
  :arguments => [
    '${1}'.freeze
  ].freeze
}

DEFAULT_MDB_FIXTURE_TOOL = {
  :executable => (ENV['RUBY'].nil? ? FilePathUtils.os_executable_ext('ruby') : ENV['RUBY'].split[0]).freeze,
  :name => 'default_mdb_fixture'.freeze,
  :stderr_redirect => StdErrRedirect::NONE.freeze,
  :optional => false.freeze,
  :arguments => [].freeze
}

def get_default_config()
  return :tools => {
    :mdb => DEFAULT_MDB_TOOL,
    :mdb_fixture => DEFAULT_MDB_FIXTURE_TOOL
  }
end
