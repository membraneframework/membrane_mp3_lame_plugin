defmodule Membrane.Element.Lame.EncoderNative do
  @moduledoc """
  This module is an interface to native lame encoder.
  """


  @on_load :load_nifs

  @doc false
  def load_nifs do
    :ok = :erlang.load_nif('./membrane_element_lame_encoder', 0)
  end


  @doc """
  Creates encoder.

  It accepts three arguments:

  - format - atom representing raw sample format,
    (TODO: big endian is not working),

  On success, returns `{:ok, resource}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On encoder initialization error, returns `{:error, {:internal, reason}}`.
  """
  @spec create(Membrane.Caps.Audio.Raw.format_t) ::
  {:ok, any} |
  {:error, {:args, atom, String.t}} |
  {:error, {:internal, atom}}
  def create(_sample_size), do: raise "NIF fail"


  @doc """
  Encodes buffer.

  It accepts two arguments:

  - resource - encoder resource,
  - data - bitstring to be encoded.

  On success, returns `{:ok, data}` where data always contain one sample in
  the same format and channels as given to `create/3`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On internal error, returns `{:error, {:internal, reason}}`.
  """
  @spec encode_buffer(any, bitstring, bitstring) ::
    {:ok, bitstring} |
    {:error, {:args, atom, String.t}} |
    {:error, {:internal, atom}}
  def encode_buffer(_encoder, _data1, _data2), do: raise "NIF fail"


  @doc """
  Destroys the encoder.

  It accepts one argument:

  - resource - encoder resource.

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On internal error, returns `{:error, {:internal, reason}}`.
  """
  @spec destroy(any) ::
    :ok |
    {:error, {:args, atom, String.t}} |
    {:error, {:internal, atom}}
  def destroy(_encoder), do: raise "NIF fail"
end
