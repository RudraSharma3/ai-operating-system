# Project Conventions

This document establishes coding standards, style preferences, git workflows, and testing patterns for this repository.

---

## 1. Code Style & Formatting

<!-- Language-specific guidelines, formatting tools (e.g. Prettier, Black, rustfmt), import ordering, and naming conventions. -->
- Follow existing file and variable naming patterns.
- Keep functions focused on a single responsibility.
- Type annotations required for public interfaces and data schemas.

## 2. Git & Version Control

- Commit format: `<type>(<scope>): <short imperative summary>`
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Do NOT include emojis in commit messages unless explicitly requested.
- Keep commits small, logical, and accompanied by clean diffs.

## 3. Error Handling & Logging

- Handle error cases explicitly; avoid empty catch/except blocks.
- Log meaningful diagnostic messages without logging sensitive user data or credentials.

## 4. Testing Conventions

- Place unit tests adjacent to implementation or in the `tests/` directory following `<module>.test.<ext>` naming.
- Use Arrange-Act-Assert (AAA) pattern.
- Test both nominal behavior and edge/error cases.
