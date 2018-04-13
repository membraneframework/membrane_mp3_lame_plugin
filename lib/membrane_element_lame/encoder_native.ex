defmodule Membrane.Element.Lame.EncoderNative do
  @moduledoc """
  This module is an interface to native lame encoder.
  """

  require Bundlex.Loader
  @on_load :load_nifs

  @doc false
  def load_nifs do
    Bundlex.Loader.load_lib_nif!(:membrane_element_lame, :membrane_element_lame_encoder)
  end

  @doc """
  Creates encoder.

  It accepts three arguments:
  - number of channels
  - bitrate
  - quality

  On success, returns `{:ok, resource}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On encoder initialization error, returns `{:error, {:internal, reason}}`.
  """
  @spec create(integer, integer, atom) ::
          {:ok, any}
          | {:error, {:args, atom, String.t()}}
          | {:error, {:internal, atom}}
  def create(_channel, _bitrate, _quality), do: raise("NIF fail")

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
  @spec encode_frame(any, bitstring) ::
          {:ok, bitstring}
          | {:error, {:args, atom, String.t()}}
          | {:error, {:internal, atom}}
  def encode_frame(_encoder, _buffer), do: raise("NIF fail")

  @doc """
  Destroys the encoder.

  It accepts one argument:

  - resource - encoder resource.

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On internal error, returns `{:error, {:internal, reason}}`.
  """
  @spec destroy(any) ::
          :ok
          | {:error, {:args, atom, String.t()}}
          | {:error, {:internal, atom}}
  def destroy(_encoder), do: raise("NIF fail")
end
