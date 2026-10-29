# 5.02 Terraform Basic Commands – Lab 1: Built-in Functions in `terraform console`

[⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-1-solution.md) | [Lab 2 ➡](tf-lab-2.md)

`terraform console` is an interactive prompt: you type a Terraform expression, and it prints the result. In this lab you use it to try Terraform's built-in functions, the same functions you will later use inside `.tf` files.

You don't need an AWS account, and you don't create anything, so the lab costs nothing.

Before you start: Terraform is installed ([5.01 Install Terraform](../5.01-install-terraform/README.md)).

## Start the console

Open the console in a new, empty folder:

```bash
mkdir tf-lab-1 && cd tf-lab-1
terraform console
```

The prompt changes to `>`. Type an expression and press **Enter**. When you finish, type `exit`.

How to write the values:
- Text goes in double quotes: `"abc"`.
- A list goes in square brackets: `["a", "b"]`.
- A map goes in curly braces, with `key = value` pairs: `{ "a" = 1, "b" = 2 }`.
- A function call is the name, then the arguments in parentheses: `max(1, 2)`.

## Tasks

| # | Task | Function |
|---|------|----------|
| 1 | Print the maximum of 19, 1 and 7. | [`max`](https://developer.hashicorp.com/terraform/language/functions/max) |
| 2 | Build a Region name: join `us`, `east` and `1` with dashes. | [`join`](https://developer.hashicorp.com/terraform/language/functions/join) |
| 3 | Encode `abcdefg` in Base64. | [`base64encode`](https://developer.hashicorp.com/terraform/language/functions/base64encode) |
| 4 | Sort the instance types `t3.small`, `m7i-flex.large` and `t3.micro` alphabetically. | [`sort`](https://developer.hashicorp.com/terraform/language/functions/sort) |
| 5 | In a map of Region codes to names (`us-east-1` = `N. Virginia`, `eu-west-1` = `Ireland`), find the name of `eu-west-1`. If the code isn't in the map, return `unknown`. | [`lookup`](https://developer.hashicorp.com/terraform/language/functions/lookup) |
| 6 | Split the VPC range `10.0.0.0/16` into `/24` subnets, and print the third one. | [`cidrsubnet`](https://developer.hashicorp.com/terraform/language/functions/cidrsubnet) |

Each function name links to its page in the Terraform documentation, with its arguments and examples.

## What's next?

Check your answers in the **[Solution](tf-lab-1-solution.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
