require "backtrace_always/version"

# TODO: eliminate this call from the backtrace
def BacktraceAlways
  raise ArgumentError, "block require" unless block_given?
  BacktraceAlways.enable!
  yield
ensure
  BacktraceAlways.disable!
end

module BacktraceAlways
  extend self

  TP = defined?(TracePoint) ? TracePoint.new(:raise) { |e|
                                return if e.raised_exception.is_a?(SystemExit)
                                spew(e.raised_exception)
                              } : false

  def output=(location)
    @output = location
  end

  def output
    @output
  end

  def enable!
    return false if @enabled

    if TP
      TP.enable
    else
      __spew__ = method(:spew)
      patch(Object, :raise) do |*args|
        begin
          __og_raise__(*args)
        rescue Exception => e         # *some* people raise this
          __spew__.call(e)
          __og_raise__(e, e.to_s, e.backtrace[1..-1])
        end
      end
    end

    @enabled = true
  end

  def disable!
    return false unless @enabled

    if TP
      TP.disable
    else
      unpatch(Object, :raise)
    end

    @enabled = false
    true
  end

  def enable_inspect!
    return false if @inspect_enabled

    __bt__ = method(:build_backtrace)
    patch(Exception, :inspect) { __bt__.call(self) }

    @inspect_enabled = true
  end

  def disable_inspect!
    return false unless @inspect_enabled

    unpatch(Exception, :inspect)

    @inspect_enabled = false
    true
  end

  private

  def patched_method(method)
    "__og_#{method}__"
  end

  def patch(klass, method, &block)
    patch = patched_method(method)
    klass.class_eval do
      alias_method patch, method
      define_method method, &block
    end
  end

  def unpatch(klass, method, &block)
    patch = patched_method(method)
    klass.class_eval do
      undef_method method
      alias_method method, patch
      undef_method patch
    end
  end

  def build_backtrace(e)
    message = sprintf("%s: %s (%s)\n", e.backtrace[1], e.message, e.class)
    e.backtrace[2..-1].inject(message) { |message, m| message << "\tfrom #{m}\n" }
  end

  def spew(e)
    out = output
    return if out.nil? && $VERBOSE.nil? # try to act like warn()

    out ||= $stderr
    out << build_backtrace(e)
  end
end
