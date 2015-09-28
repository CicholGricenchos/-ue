
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
    end

    def marshal_load
      load_from_hash Marshal.load(File.open("#{self.name}.data"){|f| f.read })
    end

    def marshal_dump
      File.open("#{self.name}.data", 'wb'){|f| f.write Marshal.dump(@all_items.collect(&:data))}
    end

    def all
      Result.new @all_items
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
    @data[name]
  end

  def inspect
    str = @data.reject{|k| k == :id}.map{|k,v| ":#{k}=>#{v.inspect}"}.join ', '
    "#<#{self.class.name}##{@data[:id].to_s.rjust(4,'0')} {#{str}}>"
  end

  class Result < Array
    def find param
      case param
      when String
        # an SQL parser is needed here
      when Hash
        self.select{|x| param.all?{|k,v| x.send(k) == v}}
      end
    end

  end

end


class Character < Model
  has_many :keyword

end

class Keyword < Model
  belongs_to :character
  has_many :dialogue
end

class Dialogue < Model
  belongs_to :keyword
end