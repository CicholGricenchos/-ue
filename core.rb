#encoding: utf-8

class Model
  attr_accessor :data

  class << self
    attr_accessor :all_items

    def has_many n
      define_method n do |param=nil|
        result = Result.new Model.const_get(n.capitalize).all_items.select{|x| x.send("#{self.class.name.downcase}_id") == self.id}
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
      all_items.freeze
    end

    def marshal_load
      load_from_hash Marshal.load(File.open("lille/#{self.name}.data"){|f| f.read })
    end

    def marshal_dump
      File.open("lille/#{self.name}.data", 'wb'){|f| f.write Marshal.dump(@all_items.collect(&:data))}
    end

    def all
      Result.new @all_items
    end

    def find param
      return self.all.find(id: param).first if param.is_a? Fixnum
      self.all.find param
    end

    alias :[] :find
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
    def find param
      case param
      when String
        # an SQL parser is needed here
      when Hash
        Result.new self.select{|x| param.all?{|k,v| x.send(k) == v}}
      end
    end

    def method_missing name, *arr, &block
      return self.first.public_send(name, *arr, &block) if self.size == 1
      raise "undefined method #{name} of #{self}"
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

State = Hash.new
State[:keywords] = ['自我介绍']

class << State
  def marshal_load
    self.clear.merge Marshal.load(File.open("lille/State.data"){|f| f.read })
  end

  def marshal_dump
    File.open("lille/State.data", 'wb'){|f| f.write Marshal.dump(self)}
  end
end

class Drama < Model
  attr_accessor :current_line, :check_points
  has_many :line

  def initialize data
    super
    @check_points = self.lines.map.with_index{|x, i| i if x.actor == 'check_point'}.compact.unshift 0
  end

  def to_check_point n
    @current_line = check_points[n]
  end

  def perform
    until self.ended?
      case @current_line.actor
      when 'system'
        EvalEnv.eval line.content, p: character[1]
      when 'check_point'
        State[:drama][id] = @check_points.index @current_line
        break
      else
        # perform dialogue
      end
      @current_line += 1
    end
  end

  def ended?
    @current_line == lines.size - 1
  end

  def started?
    !State[:drama][id].nil?
  end

end

class Line < Model
  belongs_to :drama

end

class Character < Model
  has_many :keyword
  
  def player?
    id == 1
  end

  def gain_keyword id

  end

  def greeting
    keyword.find(name: '问候').shuffle.first.dialogue
  end

  def talk
    $game_message.continue = true
    RM.show_message(content: self.appearance)
    RM.show_message(self.greeting.to_msg)
    kw = RM.select_keyword
    dlgs = keyword.find(name: kw).first.dialogue
    dlgs.map!(&:to_msg)
    RM.show_messages(dlgs)
    $game_message.continue = false
  end
end

class Keyword < Model
  belongs_to :character
  has_many :dialogue

  def meet_requirements?
    result = EvalEnv.eval requirement, p: Character[1], n: Character[character_id]
    result == false ? false : true
  end
end

class Dialogue < Model
  belongs_to :keyword
  def to_msg
    {content: content, actor_name: Character[actor.to_i].name}
  end
end