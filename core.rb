#encoding: utf-8

module RM
  def self.show_messages messages
    p messages
  end

  def self.show_message message
    p message
  end

  def self.select_keyword
    'Test'
  end

end

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

  def ask(keyword)
    dialogues = keywords.find{|x| x.name == keyword}.dialogues
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
    ask 'Greeting'
    kw = RM.select_keyword
    ask kw
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

require 'yaml'
require 'pp'

yml = <<EOF
Character:
  id: 123
  name: dare
  keywords:
    Greeting:
      - lines:
          - tetet

      - requirement: force if nil.nil?
        lines:
          - script: puts 1

    Test:
      - text
      - ok
EOF

Character.new(YAML.load(yml))
Character[123].talk
