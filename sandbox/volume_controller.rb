require_relative 'lib/dialer.rb'

DEVICE = '/dev/input/event0'

class ValueBuffer
  def initialize
    @buffer_period = 100
    @buffered_value = 0
    @last_access_time = time_now_ms
  end

  def full?
    with_access_update do
      (time_now_ms - @last_access_time) > @buffer_period
    end
  end

  def push(value)
    with_access_update do
      @buffered_value += value
    end
  end

  def flush
    with_access_update do
      value = @buffered_value
      @buffered_value = 0

      return value
    end
  end

  private

  def with_access_update
    return_value = yield
    @last_access_time = time_now_ms

    return return_value
  end

  def time_now_ms
    (Time.now.to_f * 1000).to_i
  end
end

class Adjustment
  ADJUSTMENT_RATIO = 100

  def initialize(value)
    @value = value
    @normalized_value = @value / ADJUSTMENT_RATIO
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

class VolumeController
  def initialize
    @buffer = ValueBuffer.new
  end

  def run
    volume_handler = ->(value) do
      if @buffer.full?
        puts "Full!"
        value = @buffer.flush
        adjust_volume_by(value)
      else
        puts "Pushing #{value}"
        @buffer.push(value)
      end
    end

    Dialer.new(device: DEVICE, rotate_handler: volume_handler).run
  end

  def test
    puts 'test'
  end

  def adjust_volume_by(value)
    adjustment = Adjustment.new(value)
    return if adjustment.empty?

    command = adjustment.to_cmd

    puts command
    system(command)
  end
end

VolumeController.new.run
