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

  describe ".known_source_pads/0" do
    it "should return one always available pad with all supported caps" do
      expect(described_module.known_source_pads).to eq(%{
        :sink => {:always, [
          %Membrane.Caps.Audio.Raw{format: :s8},
          %Membrane.Caps.Audio.Raw{format: :u8},
        ]}})
    end
  end

  describe ".known_sink_pads/0" do
    it "should return one always available pad with all supported caps" do
      expect(described_module.known_sink_pads).to eq(%{
        :source => {:always, [
          %Membrane.Caps.Audio.Raw{format: :s8},
          %Membrane.Caps.Audio.Raw{format: :u8},
        ]}})
    end
  end

  describe ".handle_buffer/2" do
    let :channels, do: 2
    let :format, do: :s16le
    let :caps, do: %Membrane.Caps.Audio.Raw{channels: channels, format: format}
    let :buffer, do: %Membrane.Buffer{payload: payload}
    let :state, do: %{native: native, queue: queue, caps: caps}
    let_ok :native, do: EncoderNative.create()

    context "when queue is empty and buffer is not even" do
      let :queue, do: << >>
      let :last_not_even_sample, do:
        << # s16le format, samples 1 left, 1 right, 2 left, 2 right
          5 :: integer-unit(8)-size(2)-signed-little
        >>
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

      it "queue should contain last not even sample" do
        {result, _commands, %{queue: new_queue} = state} = described_module.handle_buffer({:sink, buffer}, state)
        expect(new_queue).to eq last_not_even_sample
      end
    end

    context "when queue has sample and buffer is not even" do
      let :queue, do:
        <<
          1 :: integer-unit(8)-size(2)-signed-little
        >>
      let :payload, do:
        << # s16le format, samples 1 left, 1 right, 2 left, 2 right
          2 :: integer-unit(8)-size(2)-signed-little,
          3 :: integer-unit(8)-size(2)-signed-little,
          4 :: integer-unit(8)-size(2)-signed-little,
        >>

      it "should return an ok result" do
        {result, _commands, _new_state} = described_module.handle_buffer({:sink, buffer}, state)
        expect(result).to eq :ok
      end

      it "queue should be empty" do
        {result, _commands, %{queue: new_queue}= state} = described_module.handle_buffer({:sink, buffer}, state)
        expect(new_queue).to eq << >>
      end
    end

    context "when queue has sample and buffer is even" do
      let :queue, do:
        <<
          1 :: integer-unit(8)-size(2)-signed-little
        >>
      let :payload, do:
        << # s16le format, samples 1 left, 1 right, 2 left, 2 right
          2 :: integer-unit(8)-size(2)-signed-little,
          3 :: integer-unit(8)-size(2)-signed-little,
          4 :: integer-unit(8)-size(2)-signed-little,
          5 :: integer-unit(8)-size(2)-signed-little
        >>
      let :last_not_even_sample, do:
        << # s16le format, samples 1 left, 1 right, 2 left, 2 right
          5 :: integer-unit(8)-size(2)-signed-little
        >>

      it "should return an ok result" do
        {result, _commands, _new_state} = described_module.handle_buffer({:sink, buffer}, state)
        expect(result).to eq :ok
      end

      it "queue should be emty" do
        {result, _commands, %{queue: new_queue}= state} = described_module.handle_buffer({:sink, buffer}, state)
        expect(new_queue).to eq last_not_even_sample
      end
    end
  end
end