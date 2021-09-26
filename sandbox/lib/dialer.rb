class Dialer
  DEVICE = '/dev/input/event0'

  EVENT_ROTATE_PATTERN = /.*code 7 \(REL_DIAL\), value.*/
  EVENT_PRESS_PATTERN = /.*code 256 \(BTN_0\), value 1.*/
  EVENT_RELEASE_PATTERN = /.*code 256 \(BTN_0\), value 0.*/

  def run
    command = "evtest #{DEVICE}"
    IO.popen(command) do |io|
      while (line = io.gets) do
        case line
        when EVENT_ROTATE_PATTERN
          rotate_handler(line)
        when EVENT_PRESS_PATTERN
          press_handler(line)
        when EVENT_RELEASE_PATTERN
          release_handler(line)
        end
      end
    end
  end

  private

  def rotate_handler(line)
    value = /.*(\d)/.match(line).captures.first
    puts "ROTATE: #{value}"
  end

  def press_handler(line)
    puts "PRESSED"
  end

  def release_handler(line)
    puts "RELEASED"
  end
end

Dialer.new.run
