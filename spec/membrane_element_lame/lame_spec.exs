defmodule Membrane.Element.Lame.EncoderSpec do
  use ESpec, async: false

  alias Membrane.Element.Lame.EncoderNative

  describe ".handle_prepare/1" do
    let :previous_state, do: :stopped
    context do
      let :state, do: %{options: %Membrane.Element.Lame.Encoder{}, native: nil}
      let :context, do: %{}

      it "should return an ok result" do
        {{atom, _com}, _new_state} = described_module.handle_prepare(previous_state, state)
        expect(atom).to eq(:ok)
      end

      it "should set native in the state to encoder" do
        {{:ok, commands}, %{native: new_native}} = described_module.handle_prepare(previous_state, state)
        expect(new_native).to_not be_nil
      end
    end
  end

  describe ".handle_process1/4" do
    let :channels, do: 2
    let :format, do: :s16le
    let :caps, do: %Membrane.Caps.Audio.Raw{channels: channels, format: format}
    let :buffer, do: %Membrane.Buffer{payload: payload}
    let :state, do: %{native: native, queue: queue, eos: false}
    let :bitrate, do: 41
    let :quality, do: 5
    let :context, do: %{}
    let_ok :native, do: EncoderNative.create(channels, bitrate, quality)

    context "when queue is empty" do
      let :queue, do: << >>
      
      context "and buffer doesn't contain a frame" do
        let :payload, do: << 1 :: integer-unit(32)-size(100)-signed-little >>

        it "should return an ok result" do
          {result, _new_state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(result).to eq :ok
        end

        it "queue should be equal to payload" do
          {result, %{queue: new_queue} = state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(new_queue).to eq payload() 
        end
      end

      context "and buffer contains one frame" do
        let :payload, do: << 2 :: integer-unit(64)-size(1152) >>

        it "should return an ok result" do
          {result, _new_state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(result).to be_ok_result()
        end

        it "queue should be empty" do
          {result, %{queue: new_queue} = state}  = described_module.handle_process1(:sink, buffer, context, state)
          expect(new_queue).to eq << >>
        end
      end

      context "and buffer contains more buffers than one frame" do
        let :suffix, do: << 12 :: integer-unit(64)-size(5)>>
        let :payload, do: << 1 :: integer-unit(64)-size(1152) >> <> suffix() 

        it "should return an ok result" do
          {result, _new_state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(result).to be_ok_result()
        end

        it "queue should contain sufix of input data" do
          {result, %{queue: new_queue} = state}  = described_module.handle_process1(:sink, buffer, context, state)
          expect(new_queue).to eq suffix()
        end
      end
    end
    
    context "when queue contains 152 raw audio frames" do
      let :queue, do: << 13 :: integer-unit(64)-size(152)>>
      
      context "and buffer with queue don't contain full MPEG frame" do
        let :payload, do: << 1 :: integer-unit(32)-size(100)-signed-little >>

        it "should return an ok result" do
          {result, _new_state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(result).to eq :ok
        end

        it "queue should be equal to queue concatenated with payload" do
          {result, %{queue: new_queue} = state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(new_queue).to eq queue() <> payload() 
        end
      end

      context "and buffer contains one frame" do
        let :payload, do: << 2 :: integer-unit(64)-size(1152) >>

        it "should return an ok result" do
          {result, _new_state} = described_module.handle_process1(:sink, buffer, context, state)
          expect(result).to be_ok_result()
        end

        it "queue should contain 152 raw audio frames" do
          {result, %{queue: new_queue} = state}  = described_module.handle_process1(:sink, buffer, context, state)
          <<frame :: integer-unit(64)-size(1152), rest :: binary>> = queue <> payload
          expect(new_queue).to eq rest
        end
      end
    end
  end
end
