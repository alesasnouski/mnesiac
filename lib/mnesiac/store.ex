defmodule Mnesiac.Store do
  @moduledoc """
  Defines callback modules users can overwride
  """

  @doc """
  This function returns ths store's configuration as a keyword list.
  For more information on the options supported here, see mnesia's documenatation.

  ## Examples
  iex> store_options()
  [attributes: [...], index: [:topic_id], disc_copies: [node()]]
  """
  @callback store_options() :: term

  @callback copy_store() :: term

  @callback init_store() :: term

  @callback resolve_conflict(node()) :: term

  @optional_callbacks copy_store: 0, init_store: 0, resolve_conflict: 1

  defmacro __using__(_) do
    quote do
      @behaviour Mnesiac.Store
      @doc """
      Mnesiac will call this method to initialize the table
      """
      require Logger

      def init_store do
        :mnesia.create_table(__MODULE__, store_options())
      end

      @doc """
      Mnesiac will call this method to copy the table
      """
      def copy_store do
        for type <- [:ram_copies, :disc_copies, :disc_only_copies] do
          value = Keyword.get(store_options(), type, [])

          if Enum.member?(value, node()) do
            :mnesia.add_table_copy(__MODULE__, node(), type)
          end
        end
      end

      def resolve_conflict(cluster_node) do
        Logger.info("[mnesiac:#{node()}] #{inspect(__MODULE__)}: data found on both sides, copy aborted.")

        :ok
      end

      defoverridable Mnesiac.Store
    end
  end
end