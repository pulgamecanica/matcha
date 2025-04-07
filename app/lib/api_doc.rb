module APIDoc
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def api_doc(path, method:, &block)
      @docs ||= {}
      dsl = DSL.new
      dsl.instance_eval(&block)
      @docs[[method.to_s.upcase, path]] = dsl.data
    end

    def docs
      @docs || {}
    end
  end

  class DSL
    attr_reader :data

    def initialize
      @data = { params: [], responses: [] }
    end

    def description(text)
      @data[:description] = text
    end

    def param(name, type, required: false, desc: nil)
      @data[:params] << { name:, type:, required:, desc: }
    end

    def response(code, desc)
      @data[:responses] << { code:, desc: }
    end
  end
end
