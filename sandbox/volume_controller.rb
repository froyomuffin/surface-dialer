require_relative 'lib/dialer.rb'

DEVICE = '/dev/input/event0'

class ValueBuffer
  def initialize
    @buffered_value = 0
  end

  def push(value)
    @buffered_value += value
  end

  def flush
    value = @buffered_value
    @buffered_value = 0

    return value
  end

  private

  def time_now_ms
    (Time.now.to_f * 1000).to_i
  end
end

class Adjustment
  def initialize(value)
    @value = value
    @normalized_value =
      case
      when @value.abs <= 3
        0
      when @value.abs <= 300
        if @value > 0
          1
        else
          -1
        end
      else
        @value / 20
      end
    puts "#{@value} => #{@normalized_value}" if @value != 0
  end

  def empty?
    @normalized_value == 0
  end

  def to_cmd
    adjustment_str =
      if @normalized_value < 0
        "- #{@normalized_value.abs}"
      else
        "+ #{@normalized_value}"
      end

    "ddcutil setvcp 62 #{adjustment_str}"
  end
end

class BufferedMonitor
  def initialize
    @buffer_period = 10
    @buffer = ValueBuffer.new

    Thread.new do
      loop do
        buffered_value = @buffer.flush
        _adjust_volume_by(buffered_value)
        sleep @buffer_period.to_f / 1000
      end
    end
  end

  def adjust_volume_by(value)
    @buffer.push(value)
  end

  def toggle_mute
    code =
      if muted?
        '0x02'
      else
        '0x01'
      end

    command = "ddcutil setvcp 8D #{code}"

    system(command)
  end

  private

  def _adjust_volume_by(value)
    adjustment = Adjustment.new(value)
    return if adjustment.empty?

    command = adjustment.to_cmd

    puts command
    system(command)
  end

  def muted?
    command = 'ddcutil getvcp 8D'
    result = `#{command}`

    mute_code = /.*sl=(.*)\)/.match(result).captures&.first

    case mute_code
    when '0x02'
      false
    when '0x01'
      true
    end
  end
end

class VolumeController
  def initialize
    @monitor = BufferedMonitor.new
  end

  def run
    volume_handler = ->(value) do
      @monitor.adjust_volume_by(value)
    end

    mute_handler = ->() do
      @monitor.toggle_mute
    end

    Dialer.new(
      device: DEVICE,
      rotate_handler: volume_handler,
      press_handler: mute_handler,
    ).run
  end

end

VolumeController.new.run
