require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Syslogger" do
  it "should log to the default syslog facility, with the default options" do
    logger = Syslogger.new
    logger.should respond_to(:error)
    Syslog.should_receive(:open).with($0, Syslog::LOG_PID | Syslog::LOG_CONS, nil).and_yield(syslog=mock("syslog"))
    syslog.should_receive(:log).with(Syslog::LOG_WARNING, "Some message")
    logger.warn "Some message"
  end
  
  it "should log to the user facility, with specific options" do
    logger = Syslogger.new("my_app", Syslog::LOG_PID, Syslog::LOG_USER)
    Syslog.should_receive(:open).with("my_app", Syslog::LOG_PID, Syslog::LOG_USER).and_yield(syslog=mock("syslog"))
    syslog.should_receive(:log).with(Syslog::LOG_WARNING, "Some message")
    logger.warn "Some message"
  end
  
  %w{debug info warn error fatal unknown}.each do |logger_method|
    it "should respond to the #{logger_method.inspect} method" do
      Syslogger.new.should respond_to logger_method.to_sym
    end
  end
end
