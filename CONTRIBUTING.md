# Contributing to GymClock

Thanks for your interest in contributing to GymClock! 🏋️

## Getting Started

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature or fix
4. **Make your changes**
5. **Test** on a real device if possible (geofencing doesn't work well in simulators)
6. **Submit a Pull Request**

## Development Setup

### Requirements
- Xcode 15.0+
- iOS 17.0+ device or simulator
- watchOS 10.0+ (for watch features)
- macOS Sonoma 14.0+ (for development)

### Building
1. Open the project in Xcode
2. Select your development team for signing
3. Build and run on your target device

## Guidelines

### Code Style
- Use **SwiftUI** for all new views
- Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `@MainActor` for UI-related classes
- Prefer `async/await` over completion handlers for new code
- Add `#Preview` macros to all views

### Commit Messages
- Use clear, descriptive commit messages
- Start with a verb: "Add", "Fix", "Update", "Remove"
- Keep the first line under 72 characters
- Reference issues when applicable: "Fix #42: ..."

### Pull Requests
- Keep PRs focused — one feature or fix per PR
- Include a description of what changed and why
- Add screenshots for UI changes
- Ensure the project builds without warnings

### What We're Looking For
- Bug fixes
- Performance improvements
- New features from the [Roadmap](README.md#-roadmap)
- Documentation improvements
- Test coverage
- Accessibility improvements

### What to Avoid
- Breaking changes without discussion
- Large refactors without a tracking issue
- Dependencies on third-party libraries (we prefer first-party frameworks)

## Reporting Issues

- Use GitHub Issues
- Include device/OS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or logs if applicable

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build something cool.

---

Thanks for helping make GymClock better! 💪
