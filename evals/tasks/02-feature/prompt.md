# Task: Add JSON Output Flag to Greeter CLI

## Objective
Extend `greet.py` to support `--name <name>` and `--json` command line flags.

## Requirements
1. When `--json` is provided, `greet.py` must print a valid JSON object formatted as:
   `{"greeting": "Hello, <name>!"}`
2. If `--name` is omitted, the default name must be `"World"`.
3. If `--json` is NOT provided, standard text output `"Hello, <name>!"` must be printed.
4. All unit tests in `test_greet.py` must pass.
