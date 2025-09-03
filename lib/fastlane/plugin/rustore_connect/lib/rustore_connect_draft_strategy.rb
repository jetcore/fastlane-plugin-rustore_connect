module RustoreConnectDraftStrategy
  DELETE = 'DELETE'
  REUSE = 'REUSE'
  FAIL = 'FAIL'

  ALL = [
    DELETE,
    REUSE,
    FAIL
  ].freeze

  def self.valid?(value)
    ALL.include?(value)
  end
end