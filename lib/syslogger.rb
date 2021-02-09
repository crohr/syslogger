require 'forwardable'
require 'syslog'
require 'logger'

# Syslogger is a drop-in replacement for the standard Logger Ruby library, that logs to the syslog instead of a log file.
#
# Contrary to the SyslogLogger library, you can specify the facility and the syslog options.
#
class Syslogger
  extend Forwardable

  MUTEX = Mutex.new # :nodoc:

  attr_reader   :level, :options, :facility
  attr_accessor :ident, :formatter, :max_octets

  MAPPING = { # :nodoc:
    Logger::DEBUG   => Syslog::LOG_DEBUG,
    Logger::INFO    => Syslog::LOG_INFO,
    Logger::WARN    => Syslog::LOG_WARNING,
    Logger::ERROR   => Syslog::LOG_ERR,
    Logger::FATAL   => Syslog::LOG_CRIT,
    Logger::UNKNOWN => Syslog::LOG_ALERT
  }.freeze

  LEVELS = %w[debug info warn error fatal unknown].freeze # :nodoc:

  # Initializes default options for the logger
  #
  # <tt>ident</tt>:: the name of your program [default=<tt>$0</tt>].
  #
  # <tt>options</tt>::  syslog options [default=<tt>Syslog::LOG_PID | Syslog::LOG_CONS</tt>].
  #
  #                     Correct values are:
  #                       LOG_CONS    : writes the message on the console if an error occurs when sending the message;
  #                       LOG_NDELAY  : no delay before sending the message;
  #                       LOG_PERROR  : messages will also be written on STDERR;
  #                       LOG_PID     : adds the process number to the message (just after the program name)
  #
  # <tt>facility</tt>:: the syslog facility [default=<tt>nil</tt>]
  #
  #                     Correct values include:
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
  #   logger.info "my_subapp" { "Some lazily computed message" }
  #
  def initialize(ident = $PROGRAM_NAME, options = Syslog::LOG_PID | Syslog::LOG_CONS, facility = nil)
    @ident     = ident
    @options   = options || (Syslog::LOG_PID | Syslog::LOG_CONS)
    @facility  = facility
    @level     = Logger::INFO
    @formatter = SimpleFormatter.new
  end

  ##
  # :method: debug
  #
  # :call-seq:
  #   debug(message)
  #
  # Log message
  # +message+:: the message string.

  ##
  # :method: info
  #
  # :call-seq:
  #   info(message)
  #
  # Log message
  # +message+:: the message string.

  ##
  # :method: warn
  #
  # :call-seq:
  #   warn(message)
  #
  # Log message
  # +message+:: the message string.

  ##
  # :method: error
  #
  # :call-seq:
  #   error(message)
  #
  # Log message
  # +message+:: the message string.

  ##
  # :method: fatal
  #
  # :call-seq:
  #   fatal(message)
  #
  # Log message
  # +message+:: the message string.

  ##
  # :method: unknown
  #
  # :call-seq:
  #   unknown(message)
  #
  # Makes grease fly.
  # +message+:: the message string.

  LEVELS.each do |logger_method|
    # Accepting *args as message could be nil.
    #  Default params not supported in ruby 1.8.7
    define_method logger_method.to_sym do |*args, &block|
      severity = Logger.const_get(logger_method.upcase)
      return true if level > severity

      add(severity, nil, args.first, &block)
    end

    next if logger_method == 'unknown'.freeze

    define_method "#{logger_method}?".to_sym do
      level <= Logger.const_get(logger_method.upcase)
    end
  end

  # Log a message at the Logger::INFO level.
  def write(msg)
    add(Logger::INFO, msg)
  end
  alias <<   write
  alias puts write

  # Low level method to add a message.
  # +severity+::  the level of the message. One of Logger::DEBUG, Logger::INFO, Logger::WARN, Logger::ERROR, Logger::FATAL, Logger::UNKNOWN
  # +message+:: the message string.
  #             If nil, the method will call the block and use the result as the message string.
  #             If both are nil or no block is given, it will use the progname as per the behaviour of both the standard Ruby logger, and the Rails BufferedLogger.
  # +progname+:: optionally, overwrite the program name that appears in the log message.
  def add(severity, message = nil, progname = nil, &block)
    if message.nil? && block.nil? && !progname.nil?
      message, progname = progname, nil
    end
    progname ||= @ident
    mask = Syslog::LOG_UPTO(MAPPING[level])
    communication = message || block && block.call
    formatted_communication = clean(formatter.call(severity, Time.now, progname, communication))

    # Call Syslog
    syslog_add(progname, severity, mask, formatted_communication)
  end

  # Sets the minimum level for messages to be written in the log.
  # +level+:: one of <tt>Logger::DEBUG</tt>, <tt>Logger::INFO</tt>, <tt>Logger::WARN</tt>, <tt>Logger::ERROR</tt>, <tt>Logger::FATAL</tt>, <tt>Logger::UNKNOWN</tt>
  def level=(level)
    @level = sanitize_level(level)
  end

  # Tagging code borrowed from ActiveSupport gem
  def tagged(*tags)
    formatter.tagged(*tags) { yield self }
  end

  def_delegators :formatter, :current_tags, :push_tags, :pop_tags, :clear_tags!

  protected

  def sanitize_level(new_level) # :nodoc:
    begin
      new_level = Logger.const_get(new_level.to_s.upcase)
    rescue => _e
      raise ArgumentError.new("Invalid logger level `#{new_level.inspect}`")
    end if new_level.is_a?(Symbol)

    unless new_level.is_a?(Integer)
      raise ArgumentError.new("Invalid logger level `#{new_level.inspect}`")
    end

    new_level
  end

  # Borrowed from SyslogLogger.
  def clean(message) # :nodoc:
    message = message.to_s.dup
    message.strip! # remove whitespace
    message.gsub!(/\n/, '\\n'.freeze) # escape newlines
    message.gsub!(/%/, '%%'.freeze) # syslog(3) freaks on % (printf)
    message.gsub!(/\e\[[^m]*m/, ''.freeze) # remove useless ansi color codes
    message
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def syslog_add(progname, severity, mask, formatted_communication)
    MUTEX.synchronize do
      Syslog.open(progname, @options, @facility) do |s|
        s.mask = mask
        if max_octets
          buffer = ''
          formatted_communication.bytes do |byte|
            buffer.concat(byte)
            # if the last byte we added is potentially part of an escape, we'll go ahead and add another byte
            if buffer.bytesize >= max_octets && !['%'.ord, '\\'.ord].include?(byte)
              s.log(MAPPING[severity], buffer)
              buffer = ''
            end
          end
          s.log(MAPPING[severity], buffer) unless buffer.empty?
        else
          s.log(MAPPING[severity], formatted_communication)
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Borrowed from ActiveSupport.
  # See: https://github.com/rails/rails/blob/master/activesupport/lib/active_support/tagged_logging.rb
  class SimpleFormatter < Logger::Formatter # :nodoc:
    # This method is invoked when a log event occurs.
    def call(_severity, _timestamp, _progname, msg)
      "#{tags_text}#{msg}"
    end

    def tagged(*tags)
      new_tags = push_tags(*tags)
      yield self
    ensure
      pop_tags(new_tags.size)
    end

    def push_tags(*tags)
      tags.flatten.reject { |i| i.respond_to?(:empty?) ? i.empty? : !i }.tap do |new_tags|
        current_tags.concat(new_tags).uniq!
      end
    end

    def pop_tags(size = 1)
      current_tags.pop size
    end

    def clear_tags!
      current_tags.clear
    end

    # Fix: https://github.com/crohr/syslogger/issues/29
    # See: https://github.com/rails/rails/blob/master/activesupport/lib/active_support/tagged_logging.rb#L47
    def current_tags
      # We use our object ID here to avoid conflicting with other instances
      thread_key = @thread_key ||= "syslogger_tagged_logging_tags:#{object_id}".freeze
      Thread.current[thread_key] ||= []
    end

    def tags_text
      tags = current_tags
      tags.collect { |tag| "[#{tag}] " }.join if tags.any?
    end
  end
end
