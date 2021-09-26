class Dialer
  DEVICE = '/dev/input/event0'

  EVENT_ROTATE_PATTERN = /.*code 7 \(REL_DIAL\), value.*/
  EVENT_PRESS_PATTERN = /.*code 256 \(BTN_0\), value 1.*/
  EVENT_RELEASE_PATTERN = /.*code 256 \(BTN_0\), value 0.*/

  def initialize(
    rotate_handler: nil,
    press_handler: nil,
    release_handler: nil
  )
    @rotate_handler = rotate_handler
    @press_handler = press_handler
    @release_handler = release_handler
  end

  def run
    command = "evtest #{DEVICE}"
    IO.popen(command) do |io|
      while (line = io.gets) do
        @line = line
        case @line
        when EVENT_ROTATE_PATTERN
          rotate_handler
        when EVENT_PRESS_PATTERN
          press_handler
        when EVENT_RELEASE_PATTERN
          release_handler
        end
      end
    end
  end

  private

  def rotate_handler
    value = /.*value.*?(-?\d+)/.match(@line).captures.first
    puts "ROTATE: #{value}"

    @rotate_handler.call(value) unless @rotate_handler.nil?
  end

  def press_handler
    puts "PRESSED"

    @press_handler.call unless @press_handler.nil?
  end

  def release_handler
    puts "RELEASED"

    @release_handler.call unless @release_handler.nil?
  end
end

rotate_handler = ->(value) do
  puts "Received: #{value}"
end

Dialer.new(rotate_handler: rotate_handler).run
