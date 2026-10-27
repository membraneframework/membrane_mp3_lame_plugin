defmodule Membrane.MP3.Lame.Encoder.NativeTest do
  use ExUnit.Case, async: true

  alias Membrane.MP3.Lame.Encoder.{Native, RateControl}

  test "create rejects channel counts other than 2" do
    rate_control = RateControl.parse!(:cbr)

    assert {:error, :invalid_channels} = Native.create(1, 5, false, rate_control)
    assert {:error, :invalid_channels} = Native.create(0, 5, false, rate_control)
    assert {:ok, _ref} = Native.create(2, 5, false, rate_control)
  end
end
