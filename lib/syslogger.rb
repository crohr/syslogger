require 'syslog'
require 'logger'
require 'thread'

class Syslogger

  VERSION = "1.2.7"

  attr_reader :level, :ident, :options, :facility

  MAPPING = {
    Logger::DEBUG => Syslog::LOG_DEBUG,
    Logger::INFO => Syslog::LOG_INFO,
    Logger::WARN => Syslog::LOG_NOTICE,
    Logger::ERROR => Syslog::LOG_WARNING,
    Logger::FATAL => Syslog::LOG_ERR,
    Logger::UNKNOWN => Syslog::LOG_ALERT
  }

  #
  # Initializes default options for the logger
  # <tt>ident</tt>:: the name of your program [default=$0].
  # <tt>options</tt>::  syslog options [default=<tt>Syslog::LOG_PID | Syslog::LOG_CONS</tt>].
  #                     Correct values are:
  #                       LOG_CONS    : writes the message on the console if an error occurs when sending the message;
  #                       LOG_NDELAY  : no delay before sending the message;
  #                       LOG_PERROR  : messages will also be written on STDERR;
  #                       LOG_PID     : adds the process number to the message (just after the program name)
  # <tt>facility</tt>:: the syslog facility [default=nil] Correct values include:
  #                       Syslog::LOG_DAEMON
  #                       Syslog::LOG_USER
  #                       Syslog::LOG_SYSLOG
  #                       Syslog::LOG_LOCAL2
  #                       Syslog::LOG_NEWS
  #                       etc.
  #
  # Usage:
  #   logger = Syslogger.new("my_app", Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL0)
  #   logger.level = Logger::INFO # use Logger levels
  #   logger.warn "warning message"
  #   logger.debug "debug message"
  #
  def initialize(ident = $0, options = Syslog::LOG_PID | Syslog::LOG_CONS, facility = nil)
    @ident = ident
    @options = options || (Syslog::LOG_PID | Syslog::LOG_CONS)
    @facility = facility
    @level = Logger::INFO
    @mutex = Mutex.new
  end

  %w{debug info warn error fatal unknown}.each do |logger_method|
    # Accepting *args as message could be nil.
    #  Default params not supported in ruby 1.8.7
    define_method logger_method.to_sym do |*args, &block|
      return true if @level > Logger.const_get(logger_method.upcase)
      message = args.first || block && block.call
      add(Logger.const_get(logger_method.upcase), message)
    end

    unless logger_method == 'unknown'
      define_method "#{logger_method}?".to_sym do
        @level <= Logger.const_get(logger_method.upcase)
      end
    end
  end

  # Log a message at the Logger::INFO level. Useful for use with Rack::CommonLogger
  def write(msg)
    add(Logger::INFO, msg)
  end

  # Logs a message at the Logger::INFO level.
  def <<(msg)
    add(Logger::INFO, msg)
  end

  # Low level method to add a message.
  # +severity+::  the level of the message. One of Logger::DEBUG, Logger::INFO, Logger::WARN, Logger::ERROR, Logger::FATAL, Logger::UNKNOWN
  # +message+:: the message string. 
  #             If nil, the method will call the block and use the result as the message string. 
  #             If both are nil or no block is given, it will use the progname as per the behaviour of both the standard Ruby logger, and the Rails BufferedLogger.
  # +progname+:: optionally, overwrite the program name that appears in the log message.
  def add(severity, message = nil, progname = nil, &block)
    progname ||= @ident
    @mutex.synchronize do
      Syslog.open(progname, @options, @facility) do |s|
        s.mask = Syslog::LOG_UPTO(MAPPING[@level])
        s.log(
          MAPPING[severity], 
          clean(message || (block && block.call) || progname)
        )
      end
    end
  end

  # Sets the minimum level for messages to be written in the log.
  # +level+:: one of <tt>Logger::DEBUG</tt>, <tt>Logger::INFO</tt>, <tt>Logger::WARN</tt>, <tt>Logger::ERROR</tt>, <tt>Logger::FATAL</tt>, <tt>Logger::UNKNOWN</tt>
  def level=(level)
    level = Logger.const_get(level.to_s.upcase) if level.is_a?(Symbol)

    unless level.is_a?(Fixnum)
      raise ArgumentError.new("Invalid logger level `#{level.inspect}`")
    end

    @level = level
  end

  protected

  # Borrowed from SyslogLogger.
  def clean(message)
    message = message.to_s.dup
    message.strip!
    message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)
    message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
    message
  end
end
