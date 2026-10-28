# Task: Fix ZeroDivisionError in Calculator

## Objective
The calculator module (`calculator.py`) currently crashes with a `ZeroDivisionError` when `divide(a, b)` is called with `b == 0`.

## Requirements
1. Update `calculator.py` so that calling `divide(a, b)` with `b == 0` safely returns `None`.
2. Existing valid division (e.g. `divide(10, 2) == 5.0`) must continue to work.
3. All unit tests in `test_calculator.py` must pass.
4. Keep changes minimal and focused.
