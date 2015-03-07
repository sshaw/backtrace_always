require "rspec"
require "backtrace_always"

def foo(&block)
  ex = nil
  block ||= ->() { raise "what what what!" }

  begin
    bar(&block)
  rescue Exception => e
    ex = e
  end

  ex
end

def bar(&block)
  baz(&block)
end

def baz(&block)
  block[]
end

def silence
  old, $stderr = $stderr, StringIO.new
  yield
ensure
  $stderr = old
end

RSpec.describe BacktraceAlways do
  # (?: ... )? is for matching on Rubinius and JRuby, which include the block in foo() to the trace
  EXCEPTION_REGEX = /what what what! \(RuntimeError\)\n(?:.+\n)?.+in `baz'\n.+in `bar'\n.+in `foo'/
  EXCEPTION_INSPECT = "#<RuntimeError"

  describe "if it has not been enabled" do
    it "will not output raised exceptions to $stderr" do
      expect { foo }.to_not output.to_stderr
    end
  end

  context "when enabled" do
    before { BacktraceAlways.enable! }

    it "outputs raised exceptions and their backtrace to $stderr" do
      expect { foo }.to output(EXCEPTION_REGEX).to_stderr
    end

    it "does not override Exception#inspect" do
      e = silence { foo }
      expect(e.inspect).to start_with(EXCEPTION_INSPECT)
    end

    context "then disabled" do
      it "does not output raised exceptions to $stderr" do
        BacktraceAlways.disable!

        expect do
          foo
        end.to_not output.to_stderr
      end
    end
  end

  describe ".enable_inspect!" do
    context "when enabled" do
      before { BacktraceAlways.enable_inspect! }

      it "overrides Exception#inspect" do
        e = silence { foo }
        expect(e.inspect).to match(EXCEPTION_REGEX)
      end

      it "does not output raised exceptions to $stderr" do
        expect { foo }.to_not output.to_stderr
      end

      context "then disabled" do
        it "restores Exception#inspect" do
          BacktraceAlways.disable_inspect!

          e = silence { foo }
          expect(e.inspect).to start_with(EXCEPTION_INSPECT)
        end
      end
    end
  end

  describe ".output=" do
    before { BacktraceAlways.enable! }

    after  do
      BacktraceAlways.disable!
      BacktraceAlways.output = $stderr
    end

    it "sets the location where errors are output" do
      BacktraceAlways.output = $stdout
      expect { foo }.to output(EXCEPTION_REGEX).to_stdout
    end

    context "when given a logger" do
      it "logs to the debug level" do
        logger = double("logger")
        BacktraceAlways.output = logger

        silence { foo }
        expect(logger).to receive(:debug).with(EXCEPTION_REGEX)
      end
    end
  end
end
