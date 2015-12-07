defmodule Ev3.Mock.TouchSensor do
	@moduledoc "A mock touch sensor"

	@behaviour Ev3.Sensing

	def new() do
		%Ev3.Device{class: :sensor,
						path: "/mock/touch_sensor", 
						type: :touch}
	end

	### Sensing
	
	def senses(_) do
		[:touch]
	end

	def read(sensor, _sense) do
		value = case :random.uniform(2) - 1 do
			0 -> :released
			1 -> :pressed
    end
		{value, sensor}
	end

	def pause(_) do
		500
	end

	def sensitivity(_sensor, _sense) do
	  nil
	end

end