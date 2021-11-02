require "async"

module Async::Prefix
  refine Class do
    def async(method)
      Async::Prefix.__define_async(self, method)
    end
  end
  refine Module do
    def async(method)
      Async::Prefix.__define_async(self, method)
    end
  end
  refine Kernel do
    def async(method)
      Async::Prefix.__define_async(self, method)
    end
  end

  module_function

  def __define_async(klass, method)
    if klass.respond_to?(:instance_method)
      # @type [UnboundMethod]
      method = klass.instance_method(method)
    else
      # @type [Method]
      method = klass.method(method)
    end
    param_strings = []
    random_optional = "__async_optional_#{rand(1_000_000)}"
    method.parameters.each do |type, name|
      case type
      when :req
        param_strings << "#{name}"
      when :opt
        param_strings << "#{name} = :#{random_optional}"
      when :rest
        param_strings << "*#{name}"
      when :key
        param_strings << "#{name}: :#{random_optional}"
      when :keyreq
        param_strings << "#{name}: "
      when :keyrest
        param_strings << "**#{name}"
      when :block
        nil
      end
    end
    param_strings << "&block"
    async_arguments = method.parameters.map { |_type, name| "\"#{name}\": #{name}" }.join(", ")
    func = eval(<<~RUBY, binding, __FILE__, __LINE__)
      ->(#{param_strings.join(", ")}) do
        Async do
          Async::Prefix.__call_async(method, self, {#{async_arguments}}, block, :#{random_optional})
        end
      end
    RUBY
    if klass.respond_to?(:define_method)
      klass.define_method(method.name, func)
    else
      klass.define_singleton_method(method.name, func)
    end
  end

  def __call_async(method, caller_self, arguments, block, random_optional)
    call_args = []
    call_kwargs = {}
    method.parameters.each do |type, name|
      case type
      when :req
        call_args << arguments[name]
      when :opt
        call_args << arguments[name] unless arguments[name] == random_optional
      when :rest
        call_args += arguments[name]
      when :key
        call_kwargs[name] = arguments[name] unless arguments[name] == random_optional
      when :keyreq
        call_kwargs[name] = arguments[name]
      when :keyrest
        call_kwargs.merge!(arguments[name])
      end
    end
    if method.respond_to?(:bind)
      method.bind(caller_self).call(*call_args, **call_kwargs, &block)
    else
      caller_self.instance_exec(call_args, call_kwargs, block, method) do |args, kwargs, block, method|
        method.call(*args, **kwargs, &block)
      end
    end
  end
end
