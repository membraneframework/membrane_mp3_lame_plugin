defmodule Membrane.Element.Lame.Encoder.Native do
  @moduledoc """
  This module is an interface to native lame encoder.
  """
  use Bundlex.Loader, nif: :encoder

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
  defnif create(channel, bitrate, quality)

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
  defnif encode_frame(encoder, buffer)

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
  defnif destroy(encoder)
end
