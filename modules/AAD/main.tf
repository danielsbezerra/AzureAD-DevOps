/*
data "azuread_user" "new_user" {
  user_principal_name = var.user_email
}

resource "azuread_group" "new_group" {
  name = "my_group"
}

resource "azuread_group_member" "example" {
  group_object_id   = "${azuread_group.example.id}"
  member_object_id  = "${data.azuread_user.example.id}"
}
*/