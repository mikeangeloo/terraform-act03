resource "aws_instance" "this" {
  for_each = var.instances

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = [each.value.security_group_id]
  associate_public_ip_address = true
  key_name                    = each.value.key_name

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}