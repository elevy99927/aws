# The public half of the key you made with ssh-keygen. AWS puts it on every instance that uses this key pair.
resource "aws_key_pair" "lab" {
  key_name   = "tf-lab-key"
  public_key = file("my-ssh-key.pub")
}
