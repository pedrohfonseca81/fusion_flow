# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     FusionFlow.Repo.insert!(%FusionFlow.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`)
# and so on) as they will fail if something goes wrong.

# Seed Admin User
admin_email = "admin@admin.com"
admin_password = "admin"

if user = FusionFlow.Accounts.get_user_by_email(admin_email) do
  FusionFlow.Repo.delete!(user)
end

FusionFlow.Accounts.register_user!(%{
  email: admin_email,
  username: "admin",
  password: admin_password
})
