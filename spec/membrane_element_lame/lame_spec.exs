defmodule Membrane.Element.Lame.EncoderSpec do
  use ESpec, async: false

  alias Membrane.Element.Lame.Encoder.Native
  alias Membrane.Element.CallbackContext, as: Ctx
  @raw_frame_size 4608

  describe ".handle_stopped_to_prepared/2" do
    let :previous_state, do: :stopped

    let :state, do: %{options: %Membrane.Element.Lame.Encoder{}, native: nil}
    let :context, do: %{}

    it "should return an ok result" do
      {{atom, _com}, _new_state} =
        described_module().handle_stopped_to_prepared(context(), state())

      expect(atom) |> to(eq(:ok))
    end

    it "should initialize native resources" do
      {{:ok, _commands}, %{native: new_native}} =
        described_module().handle_stopped_to_prepared(context(), state())

      expect(new_native) |> to_not(be_nil())
    end
  end

  describe ".handle_demand/4" do
    let :pad, do: :output
    let :state, do: %{raw_frame_size: @raw_frame_size}
    let :context, do: %{}
    let :size, do: 1242

    let! :handle_demand,
      do: described_module().handle_demand(pad(), size(), unit(), context(), state())

    context "received demand in bytes" do
      let :unit, do: :bytes

      it "should return an ok result" do
        {result, _state} = handle_demand()
        expect(result) |> to(be_ok_result())
      end

      it "should keep state unchanged" do
        {_result, new_state} = handle_demand()
        expect(new_state) |> to(eq state())
      end

      it "should send demand of the same size on :input pad" do
        {{:ok, keyword_list}, _new_state} = handle_demand()
        demand = keyword_list |> Keyword.get(:demand)
        expect(demand) |> to(eq {:input, size()})
      end
    end

    context "received demand in buffers" do
      let :unit, do: :buffers

      it "should return an ok result" do
        {result, _state} = handle_demand()
        expect(result) |> to(be_ok_result())
      end

      it "should keep state unchanged" do
        {_result, new_state} = handle_demand()
        expect(new_state) |> to(eq state())
      end

      it "should send demand with multipied size by @aprox_compress_ratio" do
        {{:ok, keyword_list}, _new_state} = handle_demand()
        demand = keyword_list |> Keyword.get(:demand)
        expect(demand) |> to(eq {:input, size() * @raw_frame_size})
      end
    end
  end

  describe ".handle_process/4" do
    let :channels, do: 2
    let :format, do: :s16le
    let :caps, do: %Membrane.Caps.Audio.Raw{channels: channels(), format: format()}
    let :buffer, do: %Membrane.Buffer{payload: payload()}
    let :state, do: %{native: native(), queue: queue()}
    let :bitrate, do: 41
    let :quality, do: 5

    let :context,
      do: %Ctx.Process{
        playback_state: :playing,
        pads: %{:input => [end_of_stream?: false], :output => []}
      }

    let_ok :native, do: Native.create(channels(), bitrate(), quality())
    let :pad, do: :input

    let! :handle_process,
      do: described_module().handle_process(:input, buffer(), context(), state())

    context "when queue is empty" do
      let :queue, do: <<>>

      context "and buffer doesn't contain a frame" do
        let :payload, do: <<1::integer-unit(32)-size(100)-signed-little>>

        it "should return an ok result" do
          {result, _new_state} = handle_process()
          expect(result) |> to(eq :ok)
        end

        it "queue should be equal to payload" do
          {_result, %{queue: new_queue}} = handle_process()
          expect(new_queue) |> to(eq payload())
        end
      end

      context "and buffer contains one frame" do
        let :payload, do: <<2::integer-unit(64)-size(1152)>>

        it "should return an ok result" do
          {result, _new_state} = handle_process()
          expect(result) |> to(be_ok_result())
        end

        it "queue should be empty" do
          {_result, %{queue: new_queue}} = handle_process()
          expect(new_queue) |> to(eq <<>>)
        end

        it "should send buffer on the source pad" do
          {{_atom, keyword_list}, _new_state} = handle_process()
          buffer = keyword_list |> Keyword.get(:buffer)
          expect(buffer) |> to_not(be_nil())
          {pad, _buffer} = buffer
          expect(pad) |> to(eq :output)
        end
      end

      context "and buffer contains more buffers than one frame" do
        let :suffix, do: <<12::integer-unit(64)-size(5)>>
        let :payload, do: <<1::integer-unit(64)-size(1152)>> <> suffix()

        it "should return an ok result" do
          {result, _new_state} = handle_process()
          expect(result) |> to(be_ok_result())
        end

        it "queue should contain sufix of input data" do
          {_result, %{queue: new_queue}} = handle_process()
          expect(new_queue) |> to(eq suffix())
        end

        it "should send buffer on the source pad" do
          {{_atom, keyword_list}, _new_state} = handle_process()
          buffer = keyword_list |> Keyword.get(:buffer)
          expect(buffer) |> to_not(be_nil())
          {pad, _buffer} = buffer
          expect(pad) |> to(eq :output)
        end
      end
    end

    context "when queue contains 152 raw audio frames" do
      let :queue, do: <<13::integer-unit(64)-size(152)>>

      context "and buffer with queue don't contain full MPEG frame" do
        let :payload, do: <<1::integer-unit(32)-size(100)-signed-little>>

        it "should return an ok result" do
          {result, _new_state} = handle_process()
          expect(result) |> to(eq :ok)
        end

        it "queue should be equal to queue concatenated with payload" do
          {_result, %{queue: new_queue}} = handle_process()
          expect(new_queue) |> to(eq queue() <> payload())
        end
      end

      context "and buffer contains one frame" do
        let :payload, do: <<2::integer-unit(64)-size(1152)>>

        it "should return an ok result" do
          {result, _new_state} = handle_process()
          expect(result) |> to(be_ok_result())
        end

        it "queue should contain 152 raw audio frames" do
          {_result, %{queue: new_queue}} = handle_process()
          <<_frame::integer-unit(64)-size(1152), rest::binary>> = queue() <> payload()
          expect(new_queue) |> to(eq rest)
        end

        it "should send buffer on the source pad" do
          {{_atom, keyword_list}, _new_state} = handle_process()
          buffer = keyword_list |> Keyword.get(:buffer)
          expect(buffer) |> to_not(be_nil())
          {pad, _buffer} = buffer
          expect(pad) |> to(eq :output)
        end
      end
    end
  end
end
