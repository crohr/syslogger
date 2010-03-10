require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Syslogger" do
  it "should log to the default syslog facility, with the default options" do
    logger = Syslogger.new
    Syslog.should_receive(:open).with($0, Syslog::LOG_PID | Syslog::LOG_CONS, nil).and_yield(syslog=mock("syslog", :mask= => true))
    syslog.should_receive(:log).with(Syslog::LOG_NOTICE, "Some message")
    logger.warn "Some message"
  end
  
  it "should log to the user facility, with specific options" do
    logger = Syslogger.new("my_app", Syslog::LOG_PID, Syslog::LOG_USER)
    Syslog.should_receive(:open).with("my_app", Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog=mock("syslog", :mask= => true))
    syslog.should_receive(:log).with(Syslog::LOG_NOTICE, "Some message")
    logger.warn "Some message"
  end
  
  %w{debug info warn error fatal unknown}.each do |logger_method|
    it "should respond to the #{logger_method.inspect} method" do
      Syslogger.new.should respond_to logger_method.to_sym
    end
  end
  
  it "should respond to <<" do
    logger = Syslogger.new("my_app", Syslog::LOG_PID, Syslog::LOG_USER)
    logger.should respond_to(:<<)
    Syslog.should_receive(:open).with("my_app", Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog=mock("syslog", :mask= => true))
    syslog.should_receive(:log).with(Syslog::LOG_INFO, "yop")
    logger << "yop"
  end
  
  describe "add" do
    before do
      @logger = Syslogger.new("my_app", Syslog::LOG_PID, Syslog::LOG_USER)
    end
    it "should respond to add" do
      @logger.should respond_to(:add)
    end
    it "should correctly log" do
      Syslog.should_receive(:open).with("my_app", Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog=mock("syslog", :mask= => true))
      syslog.should_receive(:log).with(Syslog::LOG_INFO, "message")
      @logger.add(Logger::INFO, "message")
    end
    it "should take the message from the block if :message is nil" do
      Syslog.should_receive(:open).with("my_app", Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog=mock("syslog", :mask= => true))
      syslog.should_receive(:log).with(Syslog::LOG_INFO, "my message")
      @logger.add(Logger::INFO) { "my message" }
    end
    it "should use the given progname" do
      Syslog.should_receive(:open).with("progname", Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog=mock("syslog", :mask= => true))
      syslog.should_receive(:log).with(Syslog::LOG_INFO, "message")
      @logger.add(Logger::INFO, "message", "progname") { "my message" }
    end
  end
  # TODO: test logger level
end
