data "template_file" "web-config" {
    template = "${file("./init.tpl")}"

    vars {
        dbip = "${aws_instance.database1.private_ip}"
    }  
}

