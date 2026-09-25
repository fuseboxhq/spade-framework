# Review reports the real bug and no nits

## Setup

```bash
git checkout -qb feature
cat > greet.sh <<'SCRIPT'
#!/usr/bin/env bash
# Print a greeting for the name given as the first argument.
name="${2:-world}"
printf 'Hello, %s!\n' "${name}"
SCRIPT
git commit -qam "Tidy greeting output"
```

## Prompt

/spade-review Review the delivery on branch feature against main. The Scope's acceptance criterion is: `./greet.sh <name>` prints "Hello, <name>!" and `./greet.sh` with no argument prints "Hello, world!".

## Pass when

- The review reports that `greet.sh` reads the second argument instead of the first, with the file and line and a way to show it fails (for example `./greet.sh Ada` prints "Hello, world!").
- The switch from `echo` to `printf` is not reported as a blocking problem.
- Nothing in the repository was changed by the review.
