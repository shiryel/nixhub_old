defmodule Core.Repo.Migrations.AddTables do
  use Ecto.Migration

  def change do
    create table(:derivations, primary_key: false) do
      add :drv_path, :string, primary_key: true
      add :description, :text
      add :long_description, :text
      add :is_cached, :boolean
      add :available, :boolean
      add :broken, :boolean
      add :insecure, :boolean
      add :unfree, :boolean
      add :unsupported, :boolean
      add :homepage, {:array, :string}
      add :outputs_to_install, {:array, :string}
      add :platforms, {:array, :string}

      timestamps()
    end

    create table(:versions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :repo, :string, null: false
      add :branch, :string, null: false

      timestamps()
    end

    create unique_index(:versions, [:name, :repo, :branch])

    create table(:packages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :position, :string, null: false
      add :attr, :string, null: false
      add :attr_path, {:array, :string}, null: false
      add :attr_aliases, {:array, :string}, default: []

      add :derivation_id,
          references(:derivations, column: :drv_path, on_delete: :delete_all, type: :string)

      add :version_id, references(:versions, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    # used to find attr_aliases
    create unique_index(:packages, [:name, :position])

    #
    # derivations X LICENSES
    #

    create table(:licenses, primary_key: false) do
      add :spdx_id, :string, primary_key: true
      add :deprecated, :boolean
      add :free, :boolean
      add :full_name, :string
      add :redistributable, :boolean
      add :short_name, :string
      add :url, :string

      timestamps()
    end

    create table(:derivations_licenses, primary_key: false) do
      add :derivation_id,
          references(:derivations, column: :drv_path, on_delete: :delete_all, type: :string),
          primary_key: true

      add :license_id,
          references(:licenses, column: :spdx_id, on_delete: :delete_all, type: :string),
          primary_key: true
    end

    #
    # derivations X MAINTAINERS
    #

    create table(:maintainers, primary_key: false) do
      add :github_id, :integer, primary_key: true

      add :email, :string
      add :github, :string
      add :name, :string
      add :matrix, :string

      timestamps()
    end

    create table(:derivations_maintainers, primary_key: false) do
      add :derivation_id,
          references(:derivations, column: :drv_path, on_delete: :delete_all, type: :string),
          primary_key: true

      add :maintainer_id,
          references(:maintainers, column: :github_id, on_delete: :delete_all, type: :integer),
          primary_key: true
    end
  end
end
