## Terraform SSH Key Configuration

- Learned best practice for SSH key configuration in Terraform:
  - Change from hardcoded `keys = [file("~/.ssh/id_ed25519.pub")]`
  - Recommended to use a variable approach: 
    ```
    variable "ssh_public_key" { type = string }
    keys = [var.ssh_public_key]
    ```
  - This makes the configuration more flexible and portable