#encoding: utf-8

#require 'pp'

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

State = Object.new
class << State
  def load_from_marshal
    path = "State.data"
    if File.exist? path
      @data = Marshal.load(File.open(path, 'rb', &:read))
      Player.init
      Trigger.init
    else
      self.init
      Player.init
      Trigger.init
      Trigger.set_free_move(lambda { Player.gain_keyword "自我介绍" })
    end
  end

  def save_to_marshal
    path = "State.data"
    File.open(path, 'wb'){|f| f.write Marshal.dump(@data) }
  end

  def init
    @data = {}
    @data[:keywords] = []
    @data[:drama] = []
  end

  def [](*args)
    @data[*args]
  end

end

Trigger = Object.new
class << Trigger
  def init
    @data = {}
    @data[:free_move] = []
    @data[:talk] = {}
    @data[:talk_keyword] = {}
    @fiber = Fiber.new do
      loop do
        Fiber.yield
        if handler = @data[:free_move].shift
          handler.call
        end
      end
    end
    @fiber.resume
    Character.all_items.each do |c|
      talk[c] = []
      talk_keyword[c] = {}
    end
    p talk
  end

  def free_move
    @data[:free_move]
  end

  def talk
    @data[:talk]
  end

  def talk_keyword
    @data[:talk_keyword]
  end

  def set_free_move x
    free_move << x
  end

  def set_talk(character, x)
    talk[character] << x
  end

  def set_talk_keyword(character, keyword, x)
    talk_keyword[character][keyword] ||= []
    talk_keyword[character][keyword] << x
  end

  def trigger_free_move
    @fiber.resume
  end

  def trigger_talk(character)
    if handler = talk[character].shift
      handler.call
    end
  end

  def trigger_talk_keyword(character, keyword)
    if handler = (talk_keyword[character][keyword] || []).shift
      handler.call
    end
  end

end

Player = Object.new
class << Player
  attr_accessor :handlers

  def init
    @handlers = {}
    @handlers[:free_move] = []
    @handlers[:talk] = []
    @handlers[:talk_keyword] = []
  end

  def gain_keyword(str)
    keywords << str
    RM.show_message(content: "获得了关键词「#{str}」")
  end

  def keywords
    State[:keywords]
  end
end

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
      path = "#{File.dirname(__FILE__)}/Characters.data"
      File.open(path, 'rb:utf-8') do |f|
        characters = Marshal.load(f.read)
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
    return if Trigger.trigger_talk(self) == :cancel
    $game_message.continue = true
    RM.show_message(content: appearance)
    ask '问候'
    while true
      RM.show_message_without_confirm(content: '（看着我的方向。）', actor_name: self.name)
      kw = RM.select_keyword
      break if kw.nil?
      break if Trigger.trigger_talk_keyword(self, kw) == :cancel
      ask kw
    end
    ask '结束对话'
    RM.show_message(content: "结束了与#{self.name}的对话。")
    $game_message.continue = false
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
    @lines = data['lines'].map{|l| Line.new l,keyword.character }
  end

  def meet_requirement?
    return true if @requirement.nil?
    result = EvalEnv.eval @requirement, p: Player, n: keyword.character
  end
end

class Line
  attr_accessor :type, :actor, :content

  def initialize data, actor
    case data
    when String
      @type = :text
      @content = data
      @actor = actor
    else
      @actor = actor
      @type = data.keys.first.to_sym
      @content = data.values.first
    end
  end

  def to_msg
    if @actor.nil?
      actor_name = nil
    else
      actor_name = @actor.name
    end
    {content: content, actor_name: actor_name}
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

class Drama

  @all_items = []
  class << self
    attr_accessor :all_items

    def [](param)
      case param
      when Fixnum
        all_items.find{|x| x.id == param}
      when String
        all_items.find{|x| x.name == param}
      end
    end

    def load_from_marshal
      path = "#{File.dirname(__FILE__)}/Dramas.data"
      File.open(path, 'rb:utf-8') do |f|
        dramas = Marshal.load(f.read)
        dramas.each{|c| Drama.new c}
      end
    end
  end

  attr_accessor :id, :name, :sections
  def initialize(raw_data)
    drama = raw_data['Drama']
    @id = drama['id']
    @name = drama['name']
    @sections = drama['sections'].map {|data|  Section.new(self, data)}
    State[:drama][@id] ||= {:current_section => 0}
    @state = State[:drama][@id]
    set_trigger
    self.class.all_items << self
  end

  def current_section
    sections[@state[:current_section]]
  end

  def over?
    @state[:current_section] == -1
  end

  def over
    @state[:current_section] = -1
  end

  def set_trigger
    if !over?
      trigger = current_section.trigger
      lam = lambda { current_section.perform; :cancel }
      if trigger.nil?
        Trigger.set_free_move(lam)
      else
        case trigger[0]
        when :talk
          Trigger.set_talk(Character[trigger[1]], lam)
        when :talk_keyword
          Trigger.set_talk_keyword(Character[trigger[1]], trigger[2], lam)
        when :free_move
          Trigger.set_free_move(lam)
        end
      end
    end
  end

  def next_section
    @state[:current_section] += 1 
    if @state[:current_section] < sections.size
      set_trigger
    else
      over
    end
  end


end

class Section
  attr_accessor :trigger, :lines, :drama
  def initialize(drama, data)
    @drama = drama
    @trigger = data['trigger']
    trigger[0] = trigger[0].to_sym
    actor = @trigger[1] if trigger[0] == :talk
    @lines = data['lines'].map{|data| Line.new(data, Character[actor])}
  end

  def perform
    if !drama.over?
      lines.map(&:perform)
      drama.next_section
    end
  end
end

Character.load_from_marshal
State.load_from_marshal
Drama.load_from_marshal

p State