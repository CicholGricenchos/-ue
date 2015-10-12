#encoding: utf-8

class Game_Message
  attr_accessor :continue, :selecting_keyword, :current_keyword

  def continue?
    @continue
  end

  def selecting_keyword?
    @selecting_keyword
  end

  def keyword_choice?
    @selecting_keyword
  end

  def busy?
    has_text? || choice? || num_input? || item_choice? || keyword_choice?
  end
end

class Window_KeyWordItem < Window_ItemList
  def initialize(message_window)
    @message_window = message_window
    super(0, 0, Graphics.width, fitting_height(10))
    self.openness = 0
    deactivate
    set_handler(:ok,     method(:on_ok))
    set_handler(:cancel, method(:on_cancel))
  end

  def start
    refresh
    select(0)
    open
    activate
  end

  def current_item_enabled?
    true
  end

  def on_ok
    result = item
    $game_message.current_keyword = result
    $game_message.selecting_keyword = false
    close
  end

  def on_cancel
    $game_message.current_keyword = nil
    $game_message.selecting_keyword = false
    close
  end

  def make_item_list
    @data = Player.keywords
  end

  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_text_ex(rect.x, rect.y, item)
    end
  end

  def process_ok
    if current_item_enabled?
      Input.update
      deactivate
      call_ok_handler
    end
  end

  def process_cancel
    Input.update
    deactivate
    call_cancel_handler
  end
end


class Window_MessageName < Window_Base
  def initialize(message_window)
    @message_window = message_window
    super(0, 0, window_width, fitting_height(1))
    self.openness = 0
  end
  
  def window_width
    150
  end
  
  def draw_actor_name(name)
    contents.clear
    if name != ''
      self.openness = 255
      draw_text_ex 0, 0, name
    else
      self.openness = 0
    end
  end

  def update
    super
    self.x = @message_window.x
    self.y = @message_window.y - height
  end
end

class Window_Message
  
  def visible_line_number
    4
  end
  
  alias :old_create_all_windows :create_all_windows
  def create_all_windows
    old_create_all_windows
    @keyword_window = Window_KeyWordItem.new(self)
    @name_window = Window_MessageName.new(self)
  end
  
  alias :old_dispose_all_windows :dispose_all_windows
  def dispose_all_windows
    old_dispose_all_windows
    @keyword_window.dispose
    @name_window.dispose
  end
  
  alias :old_update_all_windows :update_all_windows
  def update_all_windows
    old_update_all_windows
    @keyword_window.update
    @name_window.update
  end
  
  alias :old_open_and_wait :open_and_wait
  def open_and_wait
    if !open?
      #@name_window.open
      old_open_and_wait
    end
  end
  
  alias :old_close_and_wait :close_and_wait
  def close_and_wait
    if !$game_message.continue?
      @name_window.close
      old_close_and_wait
    end
  end
  
  def process_character(c, text, pos)
    case c
    when '`'    # 名字
      sign_pos = text.index '`'
      name = text[0...sign_pos]
      text.slice!(0..sign_pos)
      @name_window.draw_actor_name(name)
    when "\r"   # 回车
      return
    when "\n"   # 换行
      process_new_line(text, pos)
    when "\f"   # 翻页
      process_new_page(text, pos)
    when "\e"   # 控制符
      process_escape_character(obtain_escape_code(text), text, pos)
    else        # 普通文字
      if pos[:x] + text_size(c).width > contents_width
        process_new_line(text, pos)
        process_normal_character(c, pos)
      else
        process_normal_character(c, pos)
      end
    end
  end

  alias :old_process_input :process_input
  def process_input
    if $game_message.selecting_keyword?
      input_keyword
    else
      old_process_input
    end
  end

  def input_keyword
    @keyword_window.start
    Fiber.yield while @keyword_window.active
  end
end


class Scene_Map
  alias :old_update :update
  def update
    old_update
    if @counter == 0
      Player.fiber_trigger(:free_move)
      @counter = 60
    else
      @counter -= 1
    end
  end

  alias :old_initialize :initialize
  def initialize
    old_initialize
    @counter = 0
  end
end

module RM
  def self.show_messages messages
    messages.each{|m| show_message m }
  end

  def self.show_message message
    message[:content] ||= ''
    name_code = message[:actor_name] ? "`#{message[:actor_name]}`" : "``"
    p name_code + message[:content]
    $game_message.add(name_code + message[:content])
    Fiber.yield while $game_message.busy?
  end

  def self.select_keyword
    $game_message.selecting_keyword = true
    Fiber.yield while $game_message.busy?
    $game_message.current_keyword
  end

end

module Foo
  def self.bar
    $game_message.continue = true
    a = {content: '这是一段很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字', actor_name: '埃里克'}
    b = {content: '2332131', actor_name: nil}
    c = {content: '2331', actor_name: '123'}
    RM.show_message a
    keyword = RM.select_keyword
    RM.show_message c
    $game_message.continue = false
  end

end