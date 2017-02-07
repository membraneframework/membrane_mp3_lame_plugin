defmodule Membrane.Element.Lame.EncoderSpec do
  use ESpec, async: false
  alias Membrane.Element.Lame.EncoderNative

  describe ".handle_caps/2" do
    context do
      let :caps, do: %Membrane.Caps.Audio.Raw{format: format, channels: channels, sample_rate: sample_rate}
      let :state, do: %{native: nil, queue: << 1, 2, 3 >>, caps: nil}

      it "should return an ok result" do
        expect(described_module.handle_caps({:sink, caps}, state)).to be_ok_result
      end

      it "should set bytes_per_interval in the state to amount of samples for given interval & sample rate without fractional part" do
        {:ok, %{bytes_per_interval: new_bytes_per_interval}} = described_module.handle_caps({:sink, caps}, state)
        expect(new_bytes_per_interval).to eq (sample_rate |> div(1 |> Membrane.Time.second |> div(interval))) * channels
      end

      it "should set queue in the state to an empty queue" do
        {:ok, %{queue: new_queue}} = described_module.handle_caps({:sink, caps}, state)
        expect(new_queue).to eq << >>
      end

      it "should set native in the state to aggregator" do
        {:ok, %{native: new_native}} = described_module.handle_caps({:sink, caps}, state)
        expect(new_native).to_not be_nil
      end

      it "should set caps in the state to aggregator" do
        {:ok, %{caps: new_caps}} = described_module.handle_caps({:sink, caps}, state)
        expect(new_caps).to eq caps
      end
    end
  end

end