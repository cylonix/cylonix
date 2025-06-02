# Contributing to Cylonix

Thank you for your interest in contributing to Cylonix! We welcome all kinds of contributions—bug reports, feature requests, documentation improvements, code changes, and more.

## Table of Contents

- [Contributing to Cylonix](#contributing-to-cylonix)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [How to Report Bugs](#how-to-report-bugs)
  - [How to Request Features](#how-to-request-features)
  - [Development Setup](#development-setup)
  - [Working on Pull Requests](#working-on-pull-requests)
  - [Coding Style](#coding-style)
  - [Running Tests](#running-tests)
  - [Commit Messages](#commit-messages)
  - [License](#license)
- [Contributing to Cylonix](#contributing-to-cylonix-1)
  - [Table of Contents](#table-of-contents-1)
  - [Code of Conduct](#code-of-conduct-1)
  - [How to Report Bugs](#how-to-report-bugs-1)
  - [How to Request Features](#how-to-request-features-1)
  - [Development Setup](#development-setup-1)
  - [Working on Pull Requests](#working-on-pull-requests-1)
  - [Coding Style](#coding-style-1)
  - [Running Tests](#running-tests-1)
  - [Commit Messages](#commit-messages-1)
  - [License](#license-1)

---

## Code of Conduct

Please read and adhere to our [Code of Conduct](docs/CODE_OF_CONDUCT.md). In short, be kind, respectful, and collaborative.

## How to Report Bugs

1. Search existing issues to see if it’s already been reported.  
2. If not, open a new issue with:
   - A clear and descriptive title.  
   - A description of the problem and expected behavior.  
   - Steps to reproduce, including platform/OS and version.  
   - Relevant logs, error messages, or screenshots.  

## How to Request Features

1. Check if a similar feature request exists; add 👍 or comments.  
2. Open a new issue and include:
   - Motivation and use cases.  
   - High-level design or API sketches.  
   - Any backward-compatibility considerations.

## Development Setup

```bash
git clone https://github.com/cylonix/cylonix.git
cd cylonix
make app-icons      # generate launcher icons
make config         # create/update local .env
make models         # build codegen models
```

Ensure you have:
- Go toolchain (see `tailscale/go.toolchain.rev`)  
- Flutter & Dart SDK  
- Xcode (for iOS/macOS) or Android SDK as needed  

## Working on Pull Requests

1. Create a topic branch off `main`:  
   ```bash
   git checkout main
   git pull
   git checkout -b feature/your-feature
   ```
2. Make your changes in that branch.  
3. Update documentation if applicable.  
4. Run tests and builds.  
5. Commit your changes with clear messages.  
6. Push to your fork and open a PR against `main`.  

## Coding Style

- Follow existing code patterns.  
- Dart/Flutter: use `dart format` and `flutter analyze`.  
- Go: use `gofmt` or `goimports`.  
- Swift: use `swiftformat` or `swiftlint` if configured.  

## Running Tests

```bash
# Dart/Flutter unit & widget tests
flutter test

# Go tests (in tailscale folder)
make test

# macOS/iOS Swift tests
xcodebuild test -scheme ShareExtension -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Commit Messages

- Use the [Conventional Commits](https://www.conventionalcommits.org/) style:
  ```
  feat(scope): add new feature
  fix(scope): handle edge case
  docs: update README
  chore: update dependencies
  ```
- Reference issues: `fixes #123`, `ref #456`.

## License

By contributing, you agree that your contributions will be licensed under the project’s [Apache 2.0 License](LICENSE).

---

Thank you for helping make Cylonix better!// filepath: /Users/randy/src/cylonix/CONTRIBUTING.md

# Contributing to Cylonix

Thank you for your interest in contributing to Cylonix! We welcome all kinds of contributions—bug reports, feature requests, documentation improvements, code changes, and more.

## Table of Contents

- [Contributing to Cylonix](#contributing-to-cylonix)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [How to Report Bugs](#how-to-report-bugs)
  - [How to Request Features](#how-to-request-features)
  - [Development Setup](#development-setup)
  - [Working on Pull Requests](#working-on-pull-requests)
  - [Coding Style](#coding-style)
  - [Running Tests](#running-tests)
  - [Commit Messages](#commit-messages)
  - [License](#license)
- [Contributing to Cylonix](#contributing-to-cylonix-1)
  - [Table of Contents](#table-of-contents-1)
  - [Code of Conduct](#code-of-conduct-1)
  - [How to Report Bugs](#how-to-report-bugs-1)
  - [How to Request Features](#how-to-request-features-1)
  - [Development Setup](#development-setup-1)
  - [Working on Pull Requests](#working-on-pull-requests-1)
  - [Coding Style](#coding-style-1)
  - [Running Tests](#running-tests-1)
  - [Commit Messages](#commit-messages-1)
  - [License](#license-1)

---

## Code of Conduct

Please read and adhere to our [Code of Conduct](docs/CODE_OF_CONDUCT.md). In short, be kind, respectful, and collaborative.

## How to Report Bugs

1. Search existing issues to see if it’s already been reported.  
2. If not, open a new issue with:
   - A clear and descriptive title.  
   - A description of the problem and expected behavior.  
   - Steps to reproduce, including platform/OS and version.  
   - Relevant logs, error messages, or screenshots.  

## How to Request Features

1. Check if a similar feature request exists; add 👍 or comments.  
2. Open a new issue and include:
   - Motivation and use cases.  
   - High-level design or API sketches.  
   - Any backward-compatibility considerations.

## Development Setup

```bash
git clone https://github.com/cylonix/cylonix.git
cd cylonix
make app-icons      # generate launcher icons
make config         # create/update local .env
make models         # build codegen models
```

Ensure you have:
- Go toolchain (see `tailscale/go.toolchain.rev`)  
- Flutter & Dart SDK  
- Xcode (for iOS/macOS) or Android SDK as needed  

## Working on Pull Requests

1. Create a topic branch off `main`:  
   ```bash
   git checkout main
   git pull
   git checkout -b feature/your-feature
   ```
2. Make your changes in that branch.  
3. Update documentation if applicable.  
4. Run tests and builds.  
5. Commit your changes with clear messages.  
6. Push to your fork and open a PR against `main`.  

## Coding Style

- Follow existing code patterns.  
- Dart/Flutter: use `dart format` and `flutter analyze`.  
- Go: use `gofmt` or `goimports`.  
- Swift: use `swiftformat` or `swiftlint` if configured.  

## Running Tests

```bash
# Dart/Flutter unit & widget tests
flutter test

# Go tests (in tailscale folder)
make test

# macOS/iOS Swift tests
xcodebuild test -scheme ShareExtension -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Commit Messages

- Use the [Conventional Commits](https://www.conventionalcommits.org/) style:
  ```
  feat(scope): add new feature
  fix(scope): handle edge case
  docs: update README
  chore: update dependencies
  ```
- Reference issues: `fixes #123`, `ref #456`.

## License

By contributing, you agree that your contributions will be licensed under the project’s [Apache 2.0 License](LICENSE).

---

Thank you for helping make Cylonix better!