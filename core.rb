
class Model
  attr_accessor :data

  class << self
    attr_accessor :all_items

    def has_many n
      define_method n do |param=nil|
        result = Result.new Model.const_get(n.capitalize).all_items.select{|x| x.send("#{self.class.name.downcase}_id") == self.id}, Model.const_get(n.capitalize)
        param.nil? ? result : result.find(param)
      end
    end

    def belongs_to n
      define_method n do
        Model.const_get(n.capitalize).all_items.select{|x| x.id == self.send("#{n}_id")}.first
      end
    end

    def load_from_hash arr
      arr.each{|h| self.new h }
    end

    def marshal_load
      load_from_hash Marshal.load(File.open("#{self.name}.data"){|f| f.read })
    end

    def marshal_dump
      File.open("#{self.name}.data", 'wb'){|f| f.write Marshal.dump(@all_items.collect(&:data))}
    end

    def all
      Result.new @all_items, self
    end

    def find param
      return self.all.find(id: param).first if param.is_a? Fixnum
      self.all.find param
    end

  end

  def initialize data
    @data = data
    self.class.all_items ||= []
    @data[:id] ||= self.class.all_items.empty? ? 1 : self.class.all_items.last.id + 1
    self.class.all_items << self
  end

  # getting data
  def method_missing name
    return @data[name] if @data[name]
    raise "undefined method #{name} of #{self}"
  end

  def inspect
    str = @data.reject{|k| k == :id}.map{|k,v| ":#{k}=>#{v.inspect}"}.join ', '
    "#<#{self.class.name}##{@data[:id].to_s.rjust(4,'0')} {#{str}}>"
  end

  def to_s
    str = @data.reject{|k| k == :id}.map{|k,v| ":#{k}=>#{v.to_s}"}.join ', '
    "#<#{self.class.name}##{@data[:id].to_s.rjust(4,'0')} {#{str}}>"
  end

  # for puts
  def to_ary
    [self.to_s]
  end

  class Result < Array
    attr_accessor :type
    def find param
      case param
      when String
        # an SQL parser is needed here
      when Hash
        Result.new self.select{|x| param.all?{|k,v| x.send(k) == v}}, self.type
      end
    end

    def initialize arr, type
      @type = type
      super arr
    end

    def method_missing name, *arr, &block
      if self.type.respond_to? name
        self.type.public_send(name, self)
      elsif self.size == 1
        self.first.public_send(name, *arr, &block)
      else
        raise "undefined method #{name} of #{self}"
      end
    end

  end

end

EvalEnv = Object.new
class << EvalEnv
  def eval expr, params={}
    params.each{|k,v| define_singleton_method(k){v}}
    instance_eval expr
  end
end

class Character < Model
  has_many :keyword
  
  def player?
    id == 1
  end
end

class Keyword < Model
  belongs_to :character
  has_many :dialogue

  def meet_requirements?
    result = EvalEnv.eval requirement, p: Character.find(1), n: Character.find(character_id)
    result == false ? false : true
  end
end

class Dialogue < Model
  belongs_to :keyword
  def self.perform arr
    arr.each{|x| puts x.content}
  end
end