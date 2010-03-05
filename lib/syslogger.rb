require 'syslog'
require 'logger'

class Syslogger
  MAPPING = {
    Logger::DEBUG => Syslog::LOG_DEBUG,
    Logger::INFO => Syslog::LOG_INFO,
    Logger::WARN => Syslog::LOG_WARNING,
    Logger::ERROR => Syslog::LOG_ERR,
    Logger::FATAL => Syslog::LOG_EMERG,
    Logger::UNKNOWN => Syslog::LOG_ALERT
  }
  # 
  # Initializes default options for the logger
  # <tt>ident</tt>:: the name of your program [default=$0]
  # <tt>options</tt>:: Syslog options [default=Syslog::LOG_PID | Syslog::LOG_CONS]
  # <tt>facility</tt>:: the syslog facility [default=nil]
  #                     correct values are Syslog::LOG_DAEMON, Syslog::LOG_USER, Syslog::LOG_SYSLOG, Syslog::LOG_LOCAL2, Syslog::LOG_NEWS, etc.
  # 
  # Usage:
  #   logger = Syslog
  def initialize(ident = $0, options = Syslog::LOG_PID | Syslog::LOG_CONS, facility = nil)
    @ident = ident
    @options = options || (Syslog::LOG_PID | Syslog::LOG_CONS)
    @facility = facility
  end
  
  %w{debug info warn error fatal unknown}.each do |logger_method|
  # {:debug => :debug, :info => :info, :warn => :warning, :error => :err, :fatal => :emerg, :unknown => :alert}.each do |logger_method, syslog_method|
    define_method logger_method.to_sym do |message|
      Syslog.open(@ident, @options, @facility) { |s| s.log(MAPPING[Logger.const_get(logger_method.upcase)], message) }
    end
  end
  
  def level=(logger_level)
    Syslog.mask = Syslog::LOG_UPTO(MAPPING.invert[logger_level])
  end
end