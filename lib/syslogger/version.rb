# frozen_string_literal: true

class Syslogger # :nodoc:
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION # :nodoc:
    MAJOR = 1
    MINOR = 6
    TINY  = 6
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end
end
