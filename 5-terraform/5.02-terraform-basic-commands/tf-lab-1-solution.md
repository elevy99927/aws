# 5.02 Terraform Basic Commands – Lab 1 Solution

[⬅ Lab 1](tf-lab-1.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md)

> Tested with Terraform v1.17.0 on 27 October 2026. The output below is copied from `terraform console`.

Start the console in an empty folder:

```bash
mkdir tf-lab-1 && cd tf-lab-1
terraform console
```

## Task 1: The maximum of 19, 1 and 7

```text
> max(19, 1, 7)
19
```

`max` takes the numbers as separate arguments. If they're in a list, expand it with `...`: `max([19, 1, 7]...)` also returns `19`.

## Task 2: Build a Region name

```text
> join("-", ["us", "east", "1"])
"us-east-1"
```

`join` takes the separator first, then the list.

## Task 3: `abcdefg` in Base64

```text
> base64encode("abcdefg")
"YWJjZGVmZw=="
```

The `==` at the end is padding. `base64decode("YWJjZGVmZw==")` turns it back into `"abcdefg"`.

## Task 4: Sort the instance types

```text
> sort(["t3.small", "m7i-flex.large", "t3.micro"])
tolist([
  "m7i-flex.large",
  "t3.micro",
  "t3.small",
])
```

`sort` compares text letter by letter, so `m` comes before `t`. The result is a list: `tolist([...])` is how the console shows it.

## Task 5: Find a Region's name

```text
> lookup({ "us-east-1" = "N. Virginia", "eu-west-1" = "Ireland" }, "eu-west-1", "unknown")
"Ireland"
```

The third argument is the default. Look up a code that isn't in the map, and you get it back:

```text
> lookup({ "us-east-1" = "N. Virginia", "eu-west-1" = "Ireland" }, "eu-central-1", "unknown")
"unknown"
```

## Task 6: The third /24 subnet of 10.0.0.0/16

```text
> cidrsubnet("10.0.0.0/16", 8, 2)
"10.0.2.0/24"
```

`cidrsubnet(prefix, newbits, netnum)`:
- `8` new bits turn the `/16` into a `/24` (16 + 8 = 24).
- `netnum` counts from **0**, so the third subnet is number `2`. The first one, `cidrsubnet("10.0.0.0/16", 8, 0)`, is `10.0.0.0/24`.

Type `exit` to close the console.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
