defmodule Membrane.MP3.Lame.Encoder.RateControl do
  @moduledoc false

  @vbr_off 0
  @vbr_mode_to_int %{mt: 1, rh: 2, abr: 3, mtrh: 4, default: 4}
  @valid_vbr_modes Map.keys(@vbr_mode_to_int)

  @enforce_keys [
    :type,
    :bitrate,
    :quality,
    :mean_bitrate,
    :min_bitrate,
    :max_bitrate,
    :hard_min
  ]
  defstruct @enforce_keys

  @spec parse!(:cbr | {:cbr | :vbr, Keyword.t()}) :: %__MODULE__{}
  def parse!(:cbr), do: parse!({:cbr, []})

  def parse!({:cbr, config}) when is_list(config) do
    unless Keyword.keyword?(config) do
      raise ArgumentError, "CBR config must be a keyword list, got: #{inspect(config)}"
    end

    config = Keyword.validate!(config, bitrate: 192)
    bitrate = Keyword.fetch!(config, :bitrate)

    unless is_integer(bitrate) and bitrate > 0 do
      raise ArgumentError,
            "CBR :bitrate must be a positive integer (kbps), got: #{inspect(bitrate)}"
    end

    %__MODULE__{
      type: @vbr_off,
      bitrate: bitrate,
      quality: -1.0,
      mean_bitrate: -1,
      min_bitrate: -1,
      max_bitrate: -1,
      hard_min: false
    }
  end

  def parse!({:vbr, config}) when is_list(config) do
    unless Keyword.keyword?(config) do
      raise ArgumentError, "VBR config must be a keyword list, got: #{inspect(config)}"
    end

    config =
      config
      |> Keyword.validate!(
        mode: nil,
        quality: nil,
        mean_bitrate: nil,
        min_bitrate: nil,
        max_bitrate: nil,
        hard_min: false
      )
      |> Map.new()

    validate_config_fields!(config)

    %__MODULE__{
      type: Map.fetch!(@vbr_mode_to_int, config.mode),
      bitrate: -1,
      quality: (config.quality || -1) * 1.0,
      mean_bitrate: config.mean_bitrate || -1,
      min_bitrate: config.min_bitrate || -1,
      max_bitrate: config.max_bitrate || -1,
      hard_min: config.hard_min
    }
  end

  def parse!(value) do
    raise ArgumentError, "Invalid rate_control: #{inspect(value)}"
  end

  # LLM-generated validation
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp validate_config_fields!(config) do
    unless config.mode in @valid_vbr_modes do
      raise ArgumentError,
            "VBR :mode must be one of #{inspect(@valid_vbr_modes)}, got: #{inspect(config.mode)}"
    end

    if config.mode == :abr and config.mean_bitrate == nil do
      raise ArgumentError, ":mean_bitrate is required for :abr VBR mode"
    end

    if config.mode != :abr and config.mean_bitrate != nil do
      raise ArgumentError,
            ":mean_bitrate is only valid for :abr VBR mode, got mode: #{inspect(config.mode)}"
    end

    if config.mode == :abr and not is_nil(config.quality) do
      raise ArgumentError, ":quality is not applicable for :abr VBR mode"
    end

    unless config.quality == nil or (config.quality >= 0 and config.quality < 10) do
      raise ArgumentError,
            "VBR :quality must be a number in [0, 10) range, got: #{inspect(config.quality)}"
    end

    for {key, value} <- Map.take(config, [:mean_bitrate, :min_bitrate, :max_bitrate]),
        value,
        not (is_integer(value) and value > 0) do
      raise ArgumentError,
            "VBR #{inspect(key)} must be a positive integer (kbps), got: #{inspect(value)}"
    end

    unless is_boolean(config.hard_min) do
      raise ArgumentError, "VBR :hard_min must be a boolean, got: #{inspect(config.hard_min)}"
    end
  end
end
