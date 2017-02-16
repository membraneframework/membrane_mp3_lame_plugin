defmodule Membrane.Element.Lame.EncoderSpec do
  use ESpec, async: false

  alias Membrane.Element.Lame.EncoderNative

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

  describe ".handle_buffer/2" do
    let :channels, do: 2
    let :format, do: :s16le
    let :caps, do: %Membrane.Caps.Audio.Raw{channels: channels, format: format}
    let :state, do: %{native: native, queue: << >>, caps: caps}
    let :buffer, do: %Membrane.Buffer{payload: payload}
    let_ok :native, do: EncoderNative.create()
    let :payload, do:
      << # s16le format, samples 1 left, 1 right, 2 left, 2 right
        1 :: integer-unit(8)-size(2)-signed-little,
        2 :: integer-unit(8)-size(2)-signed-little,
        3 :: integer-unit(8)-size(2)-signed-little,
        4 :: integer-unit(8)-size(2)-signed-little,
        5 :: integer-unit(8)-size(2)-signed-little
      >>

    it "should return an ok result" do
      {result, _commands, _new_state} = described_module.handle_buffer({:sink, buffer}, state)
      expect(result).to eq :ok
    end
  end
end