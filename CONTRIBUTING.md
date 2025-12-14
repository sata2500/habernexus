# Contributing to HaberNexus

First off, thanks for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to HaberNexus. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for HaberNexus. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps to reproduce the problem** in as much detail as possible.
- **Provide specific examples** to demonstrate the steps.
- **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
- **Explain which behavior you expected to see instead and why.**

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for HaberNexus, including completely new features and minor improvements to existing functionality.

- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description of the suggested enhancement** in as much detail as possible.
- **Explain why this enhancement would be useful** to most HaberNexus users.

### Pull Requests

The process described here has several goals:

- Maintain HaberNexus's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible HaberNexus
- Enable a sustainable system for HaberNexus's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

1.  Follow all instructions in [the template](PULL_REQUEST_TEMPLATE.md)
2.  Follow the [styleguides](#styleguides)
3.  After you submit your pull request, verify that all status checks are passing

## Styleguides

### Python Styleguide

- Use [Black](https://github.com/psf/black) for code formatting.
- Use [isort](https://github.com/PyCQA/isort) for import sorting.
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/).
- Write docstrings for all public modules, classes, and methods.

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

## Setting Up Development Environment

1.  Clone the repository
2.  Copy `.env.example` to `.env` and configure environment variables
3.  Run `docker-compose up -d` to start services
4.  Run migrations: `docker-compose exec web python manage.py migrate`
5.  Create superuser: `docker-compose exec web python manage.py createsuperuser`

Happy hacking! 🚀
