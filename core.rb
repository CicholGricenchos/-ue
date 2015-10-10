#encoding: utf-8

=begin
module RM
  def self.show_messages messages
    p messages
  end

  def self.show_message message
    puts message[:content]
  end

  def self.select_keyword
    nil
  end

end
=end

EvalEnv = Object.new
class << EvalEnv
  def force
    :force
  end

  def eval expr, params={}
    params.each{|k,v| define_singleton_method(k){v}}
    instance_eval expr
  end
end

Player = Object.new

class Character

  @all_items = []
  class << self
    attr_accessor :all_items

    def [](param)
      case param
      when Fixnum
        Character.all_items.find{|x| x.id == param}
      when String
        Character.all_items.find{|x| x.name == param}
      end
    end

    def load_from_marshal
      recover = lambda do |obj|
        case obj
        when String
          obj.split('.').map{|x| x.to_i.chr(Encoding.find('utf-8'))}.join
        when Array
          obj.map{|x| recover[x]}
        when Hash
          new_hash = {}
          obj.each do |k,v|
            new_hash[recover[k]] = recover[v]
          end
          new_hash
        else obj
        end
      end
      path = "#{File.dirname(__FILE__)}/Characters.data"
      File.open(path, 'r:utf-8') do |f|
        characters = recover.call(Marshal.load(f.read))
        characters.each{|c| Character.new c}
      end
    end
  end

  attr_accessor :id, :name, :appearance, :keywords
  def initialize(raw_data)
    character = raw_data['Character']
    @id = character['id']
    @name = character['name']
    @appearance = character['appearance']
    @keywords = character['keywords'].map{|k, v| Keyword.new self, k, v}
    self.class.all_items << self
  end

  def ask(keyword_name)
    keyword = keywords.find{|x| x.name == keyword_name}
    ask "不明" and return if !keyword
    dialogues = keyword.dialogues
    dialogues.select!(&:meet_requirement?)
    if dialogue = dialogues.find{|x| x.meet_requirement? == :force}
    else
      dialogue = dialogues.shuffle.first
    end
    dialogue.lines.each(&:perform)
  end

  def talk
    #$game_message.continue = true
    RM.show_message(content: appearance)
    ask '问候'
    while true
      RM.show_message(content: '（看着我的方向。）', actor_name: self.name)
      kw = RM.select_keyword
      break if kw.nil?
      ask kw
    end
    RM.show_message(content: "结束了与#{self.name}的对话。")
    #$game_message.continue = false
  end

end

class Keyword
  attr_accessor :name, :dialogues, :character
  def initialize character, name, dialogues
    @name = name
    @character = character
    if dialogues.any?{|line| line.is_a? String}
      @dialogues = [Dialogue.new(self, {'lines'=> dialogues})]
    else
      @dialogues = dialogues.map{|data| Dialogue.new self, data }
    end
  end
end

class Dialogue
  attr_accessor :requirement, :lines, :keyword
  def initialize keyword, data
    @keyword = keyword
    @requirement = data['requirement']
    @lines = data['lines'].map{|l| Line.new self,l }
  end

  def meet_requirement?
    return true if @requirement.nil?
    result = EvalEnv.eval @requirement, p: Player, n: keyword.character
  end
end

class Line
  attr_accessor :type, :actor, :content, :dialogue
  
  def default_character
    dialogue.keyword.character
  end

  def initialize dialogue, data
    @dialogue = dialogue
    case data
    when String
      @type = :text
      @content = data
      @actor = default_character
    else
      @type = data.keys.first.to_sym
      @content = data.values.first
    end
  end

  def to_msg
    {content: content, actor_name: @actor.name}
  end

  def perform
    case @type
    when :text
      RM.show_message to_msg
    when :script
      EvalEnv.eval @content
    end
  end
end

Character.load_from_marshal

State = Hash.new
State[:keywords] = ['自我介绍']