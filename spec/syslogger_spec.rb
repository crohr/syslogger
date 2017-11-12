require 'spec_helper'

describe Syslogger do

  let(:fake_syslog) { double('syslog', :mask= => true) }

  describe '.new' do
    it 'should log to the default syslog facility, with the default options' do
      logger = Syslogger.new
      expect(Syslog).to receive(:open).with($0, Syslog::LOG_PID | Syslog::LOG_CONS, nil).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_WARNING, 'Some message')
      logger.warn 'Some message'
    end

    it 'should log to the user facility, with specific options' do
      logger = Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER)
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_WARNING, 'Some message')
      logger.warn 'Some message'
    end
  end

  describe '#add' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    it 'should respond to add' do
      expect(logger).to respond_to(:add)
    end

    it 'should correctly log' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.add(Logger::INFO, 'message')
    end

    it 'should take the message from the block if :message is nil' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.add(Logger::INFO) { 'message' }
    end

    it 'should use the given progname' do
      expect(Syslog).to receive(:open).with('progname', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.add(Logger::INFO, 'message', 'progname')
    end

    it 'should use the default progname when message is passed in progname' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.add(Logger::INFO, nil, 'message')
    end

    it 'should use the given progname if message is passed in block' do
      expect(Syslog).to receive(:open).with('progname', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.add(Logger::INFO, nil, 'progname') { 'message' }
    end

    it "should substitute '%' for '%%' before adding the :message" do
      allow(Syslog).to receive(:open).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, "%%me%%ssage%%")
      logger.add(Logger::INFO, "%me%ssage%")
    end

    it 'should clean formatted message' do
      allow(Syslog).to receive(:open).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, "m%%e%%s%%s%%a%%g%%e")

      original_formatter = logger.formatter

      begin
        logger.formatter = proc do |severity, datetime, progname, msg|
          msg.split(//).join('%')
        end
        logger.add(Logger::INFO, 'message')
      ensure
        logger.formatter = original_formatter
      end
    end

    it 'should clean tagged message' do
      allow(Syslog).to receive(:open).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, "[t%%a%%g%%g%%e%%d] [it] message")

      logger.tagged("t%a%g%g%e%d") do
        logger.tagged('it') do
          logger.add(Logger::INFO, 'message')
        end
      end
    end

    it 'should strip the :message' do
      allow(Syslog).to receive(:open).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.add(Logger::INFO, "\n\nmessage  ")
    end

    it 'should not raise exception if asked to log with a nil message and body' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, '')
      expect {
        logger.add(Logger::INFO, nil)
      }.to_not raise_error
    end

    it 'should send an empty string if the message and block are nil' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, '')
      logger.add(Logger::INFO, nil)
    end

    it 'should split string over the max octet size' do
      logger.max_octets = 480
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'a' * 480).twice
      logger.add(Logger::INFO, 'a' * 960)
    end

    it 'should apply the log formatter to the message' do
      allow(Syslog).to receive(:open).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'test message!')
      logger.formatter = proc do |severity, datetime, progname, msg|
        "test #{msg}!"
      end
      logger.add(Logger::INFO, 'message')
    end
  end

  describe '#<<' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    it 'should respond to <<' do
      expect(logger).to respond_to(:<<)
    end

    it 'should correctly log' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger << 'message'
    end
  end

  describe '#puts' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    it 'should respond to puts' do
      expect(logger).to respond_to(:puts)
    end

    it 'should correctly log' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.puts 'message'
    end
  end

  describe '#write' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    it 'should respond to write' do
      expect(logger).to respond_to(:write)
    end

    it 'should correctly log' do
      expect(Syslog).to receive(:open).with('my_app', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log).with(Syslog::LOG_INFO, 'message')
      logger.write 'message'
    end
  end

  describe '#max_octets=' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    it 'should set the max_octets for the logger' do
      expect { logger.max_octets = 1 }.to change(logger, :max_octets)
      expect(logger.max_octets).to eq 1
    end
  end

  describe '#ident=' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID | Syslog::LOG_CONS, nil) }

    it 'should permanently change the ident string' do
      logger.ident = 'new_ident'
      expect(Syslog).to receive(:open).with('new_ident', Syslog::LOG_PID | Syslog::LOG_CONS, nil).and_yield(fake_syslog)
      expect(fake_syslog).to receive(:log)
      logger.warn('should get the new ident string')
    end
  end

  describe '#level=' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    { :debug => Logger::DEBUG,
      :info  => Logger::INFO,
      :warn  => Logger::WARN,
      :error => Logger::ERROR,
      :fatal => Logger::FATAL
    }.each_pair do |level_symbol, level_value|
      it "should allow using :#{level_symbol}" do
        logger.level = level_symbol
        expect(logger.level).to eq level_value
      end

      it "should allow using Integer #{level_value}" do
        logger.level = level_value
        expect(logger.level).to eq level_value
      end
    end

    it 'should not allow using random symbols' do
      expect {
        logger.level = :foo
      }.to raise_error(ArgumentError)
    end

    it 'should not allow using symbols mapping back to non-level constants' do
      expect {
        logger.level = :version
      }.to raise_error(ArgumentError)
    end

    it 'should not allow using strings' do
      expect {
        logger.level = 'warn'
      }.to raise_error(ArgumentError)
    end
  end

  describe '#:level? methods' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }

    %w{debug info warn error fatal}.each do |logger_method|
      it "should respond to the #{logger_method}? method" do
        expect(logger).to respond_to "#{logger_method}?".to_sym
      end
    end

    it 'should not have unknown? method' do
      expect(logger).to_not respond_to :unknown?
    end

    context 'when loglevel is Logger::DEBUG' do
      it 'should return true for all methods' do
        logger.level = Logger::DEBUG
        %w{debug info warn error fatal}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be true
        end
      end
    end

    context 'when loglevel is Logger::INFO' do
      it 'should return true for all except debug?' do
        logger.level = Logger::INFO
        %w{info warn error fatal}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be true
        end
        expect(logger.debug?).to be false
      end
    end

    context 'when loglevel is Logger::WARN' do
      it 'should return true for warn?, error? and fatal? when WARN' do
        logger.level = Logger::WARN
        %w{warn error fatal}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be true
        end
        %w{debug info}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be false
        end
      end
    end

    context 'when loglevel is Logger::ERROR' do
      it 'should return true for error? and fatal? when ERROR' do
        logger.level = Logger::ERROR
        %w{error fatal}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be true
        end
        %w{warn debug info}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be false
        end
      end
    end

    context 'when loglevel is Logger::FATAL' do
      it 'should return true only for fatal? when FATAL' do
        logger.level = Logger::FATAL
        expect(logger.fatal?).to be true
        %w{error warn debug info}.each do |logger_method|
          expect(logger.send("#{logger_method}?")).to be false
        end
      end
    end
  end

  describe '#push_tags' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }
    after(:each) { logger.clear_tags! }

    it 'saves tags' do
      logger.push_tags('tag1')
      logger.push_tags('tag2')
      expect(logger.current_tags).to eq ['tag1', 'tag2']
    end

    it 'saves uniq tags' do
      logger.push_tags('tag1')
      logger.push_tags('tag2')
      logger.push_tags('foo')
      logger.push_tags('foo')
      expect(logger.current_tags).to eq ['tag1', 'tag2', 'foo']
    end
  end

  describe '#clear_tags!' do
    let(:logger) { Syslogger.new('my_app', Syslog::LOG_PID, Syslog::LOG_USER) }
    after(:each) { logger.clear_tags! }

    it 'clears tags' do
      expect(logger.current_tags).to eq []
      logger.push_tags('tag1')
      logger.push_tags('tag2')
      expect(logger.current_tags).to eq ['tag1', 'tag2']
      logger.clear_tags!
      expect(logger.current_tags).to eq []
    end
  end

  describe 'logger methods (debug info warn error fatal unknown)' do
    %w{debug info warn error fatal unknown}.each do |logger_method|

      it "should respond to the #{logger_method.inspect} method" do
        expect(Syslogger.new).to respond_to logger_method.to_sym
      end

      it "should log #{logger_method} without raising an exception if called with a block" do
        severity = Syslogger::MAPPING[Logger.const_get(logger_method.upcase)]

        logger = Syslogger.new
        logger.level = Logger.const_get(logger_method.upcase)

        expect(Syslog).to receive(:open).and_yield(fake_syslog)
        expect(fake_syslog).to receive(:log).with(severity, 'Some message that dont need to be in a block')
        expect {
          logger.send(logger_method.to_sym) { 'Some message that dont need to be in a block' }
        }.to_not raise_error
      end

      it "should log #{logger_method} using message as progname with the block's result" do
        severity = Syslogger::MAPPING[Logger.const_get(logger_method.upcase)]

        logger = Syslogger.new
        logger.level = Logger.const_get(logger_method.upcase)

        expect(Syslog).to receive(:open).with('Woah', anything, nil).and_yield(fake_syslog)
        expect(fake_syslog).to receive(:log).with(severity, 'Some message that really needs a block')
        expect {
          logger.send(logger_method.to_sym, 'Woah') { 'Some message that really needs a block' }
        }.to_not raise_error
      end

      it "should log #{logger_method} without raising an exception if called with a nil message" do
        logger = Syslogger.new
        expect {
          logger.send(logger_method.to_sym, nil)
        }.to_not raise_error
      end

      it "should log #{logger_method} without raising an exception if called with a no message" do
        logger = Syslogger.new
        expect {
          logger.send(logger_method.to_sym)
        }.to_not raise_error
      end

      it "should log #{logger_method} without raising an exception if message splits on an escape" do
        logger = Syslogger.new
        logger.max_octets = 100
        msg  = 'A' * 99
        msg += "%BBB"
        expect {
          logger.send(logger_method.to_sym, msg)
        }.to_not raise_error
      end
    end
  end

  describe 'it should be thread safe' do
    it 'should not fail under chaos' do
      threads = []
      (1..10).each do
        threads << Thread.new do
          (1..100).each do |index|
            logger = Syslogger.new(Thread.current.inspect, Syslog::LOG_PID, Syslog::LOG_USER)
            logger.write index
          end
        end
      end

      threads.map(&:join)
    end

    it 'should allow multiple instances to log at the same time' do
      logger1 = Syslogger.new('my_app1', Syslog::LOG_PID, Syslog::LOG_USER)
      logger2 = Syslogger.new('my_app2', Syslog::LOG_PID, Syslog::LOG_USER)

      syslog1 = double('syslog1', :mask= => true)
      syslog2 = double('syslog2', :mask= => true)

      expect(Syslog).to receive(:open).exactly(5000).times.with('my_app1', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog1)
      expect(Syslog).to receive(:open).exactly(5000).times.with('my_app2', Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog2)

      expect(syslog1).to receive(:log).exactly(5000).times.with(Syslog::LOG_INFO, 'logger1')
      expect(syslog2).to receive(:log).exactly(5000).times.with(Syslog::LOG_INFO, 'logger2')

      threads = []

      threads << Thread.new do
        5000.times do |i|
          logger1.info 'logger1'
        end
      end

      threads << Thread.new do
        5000.times do |i|
          logger2.info 'logger2'
        end
      end

      threads.map(&:join)
    end
  end

  describe 'it should respect loglevel precedence when logging' do
    %w{debug info warn error}.each do |logger_method|
      it "should not log #{logger_method} when level is higher" do
        logger = Syslogger.new
        logger.level = Logger::FATAL
        expect(Syslog).to_not receive(:open).with($0, Syslog::LOG_PID | Syslog::LOG_CONS, nil).and_yield(fake_syslog)
        expect(fake_syslog).to_not receive(:log).with(Syslog::LOG_NOTICE, 'Some message')
        logger.send(logger_method.to_sym, 'Some message')
      end

      it "should not evaluate a block or log #{logger_method} when level is higher" do
        logger = Syslogger.new
        logger.level = Logger::FATAL
        expect(Syslog).to_not receive(:open).with($0, Syslog::LOG_PID | Syslog::LOG_CONS, nil).and_yield(fake_syslog)
        expect(fake_syslog).to_not receive(:log).with(Syslog::LOG_NOTICE, 'Some message')
        logger.send(logger_method.to_sym) { violated 'This block should not have been called' }
      end
    end
  end
end
