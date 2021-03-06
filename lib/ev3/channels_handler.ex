defmodule Ev3.ChannelsHandler do
	@moduledoc "Phoenix channels handler"

	use GenEvent
	require Logger
  alias Ev3.Endpoint
  alias Ev3.Percept
  alias Ev3.Motive
  alias Ev3.Memory

  @dashboard "ev3:dashboard"

	### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

  def handle_event(:faint, state) do
    Endpoint.broadcast!(@dashboard, "active_state", %{active: false})
		{:ok, state}
	end

  def handle_event(:revive, state) do
    Endpoint.broadcast!(@dashboard, "active_state", %{active: true})
		{:ok, state}
	end

  def handle_event({:perceived, %Percept{about: about, value: value}}, state) do
		Endpoint.broadcast!(@dashboard, "percept", %{about: stringify(about), value: stringify(value)})
		{:ok, state}
	end

	def handle_event({:motivated, %Motive{about: about, value: value}}, state) do
		Endpoint.broadcast!(@dashboard, "motive", %{about: stringify(about), on: value == :on, inhibited: Memory.inhibited?(about)})
		{:ok, state}
	end

  def handle_event({:behavior_started, name, reflex} ,state) do
    Endpoint.broadcast!(@dashboard, "behavior", %{name: name, reflex: reflex, event: "started", value: ""})
    {:ok, state}
  end
  
  def handle_event({:behavior_stopped, name, reflex} ,state) do
    Endpoint.broadcast!(@dashboard, "behavior", %{name: name, reflex: reflex, event: "stopped", value: ""})
    {:ok, state}
  end
  
  def handle_event({:overwhelmed, :behavior, name} ,state) do
    Endpoint.broadcast!(@dashboard, "behavior", %{name: name, reflex: false, event: "overwhelmed", value: ""})
    {:ok, state}
  end
  
  def handle_event({:behavior_inhibited, name} ,state) do
    Endpoint.broadcast!(@dashboard, "behavior", %{name: name, reflex: false, event: "inhibited", value: ""})
    {:ok, state}
  end
  
  def handle_event({:behavior_transited, name, to_state}, state) do
    Endpoint.broadcast!(@dashboard, "behavior", %{name: name, reflex: false, event: "transited", value: to_state})
    {:ok, state}
  end

  def handle_event({:behavior_reflexed, behavior_name, {percept_name, percept_value}}, state) do
    Endpoint.broadcast!(@dashboard, "behavior", %{name: behavior_name, reflex: true, event: "transited", value: "#{stringify(percept_name)} #{stringify(percept_value)}"})
    {:ok, state}
  end

  def handle_event({:realized, actuator_name, intent}, state) do
    Endpoint.broadcast!(@dashboard, "intent", %{actuator: actuator_name, about: stringify(intent.about), value: "#{stringify(intent.value)}", strong: intent.strong})
		{:ok, state}
	end

  def handle_event({:runtime_stats, stats}, state) do
    Endpoint.broadcast!(@dashboard, "runtime_stats", stats)
    {:ok, state}
  end
  
	def handle_event(_event, state) do
    #		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

  ### PRIVATE

  defp stringify(x) do
    case x do
      s when is_binary(s) -> s
      y when is_atom(y) or is_number(y) -> to_string(y)
      m when is_map(m) -> map_to_string(m)
      {a, v1, nil} -> "{#{stringify(a)}, #{stringify(v1)}}"
      {a, v1, v2} -> "{#{stringify(a)}, #{stringify(v1)}, #{stringify(v2)}}"
      {a, v} -> "{#{stringify(a)}, #{stringify(v)}}"
      z -> "#{inspect z}"
    end
  end

  defp map_to_string(m) do
    Map.keys(m)
    |> Enum.reduce("",
      fn(key, acc) ->
        acc <> "#{key}=#{stringify(Map.get(m,key))} "
      end
    )
  end
 

end
