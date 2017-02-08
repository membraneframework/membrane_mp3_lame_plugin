defmodule Membrane.Element.Lame.EncoderSpec do
  use ESpec, async: false

  describe ".handle_caps/2" do
    context do
      let :caps, do: %Membrane.Caps.Audio.Raw{channels: nil, sample_rate: nil, format: nil}
      let :state, do: %{native: nil, queue: << 1, 2, 3 >>, caps: nil}

      it "should return an ok result" do
        expect(described_module.handle_caps({:sink, caps}, state)).to be_ok_result
      end

      it "should set queue in the state to an empty queue" do
        {:ok, %{queue: new_queue}} = described_module.handle_caps({:sink, caps}, state)
        expect(new_queue).to eq << >>
      end

      it "should set native in the state to encoder" do
        {:ok, %{native: new_native}} = described_module.handle_caps({:sink, caps}, state)
        expect(new_native).to_not be_nil
      end
    end
  end
end