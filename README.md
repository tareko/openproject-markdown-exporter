# Meeting Markdown Export Plugin

This plugin adds a "Export Markdown" menu item to the Meetings module in OpenProject, allowing users to export meetings as Markdown files.

## Features

- Export meetings to Markdown format
- Include participants (optional)
- Include outcomes/decisions (optional)
- Clean, well-formatted markdown output
- Test-driven development approach

## Development Environment

This plugin uses Docker for a consistent development environment. The setup uses the existing OpenProject Docker configuration.

### Prerequisites

- Docker and Docker Compose installed
- Docker Compose v2 or `docker-compose` v1
- Sufficient system resources (4GB RAM minimum recommended)
- OpenProject base Docker environment available

### Quick Start

1. **Setup the test environment** (run once):
   ```bash
   cd plugins/openproject-meeting-markdown-export
   ./bin/test setup
   ```

2. **Run all tests**:
   ```bash
   ./bin/test all
   ```

3. **Run specific test types**:
   ```bash
   # Unit tests only
   ./bin/test unit
   
   # Integration tests only
   ./bin/test integration
   
   # Feature tests (requires Selenium)
   ./bin/test feature
   ```

4. **Run a specific test file**:
   ```bash
   ./bin/test all --focus spec/workers/meetings/markdown_exporter_spec.rb
   ```

5. **Clean up**:
   ```bash
   ./bin/test clean
   ```

### Available Commands

| Command | Description |
|---------|-------------|
| `setup` | Setup the test environment (run once) |
| `unit` | Run unit tests only |
| `integration` | Run integration tests only |
| `feature` | Run feature tests (requires Selenium) |
| `all` | Run all tests |
| `clean` | Clean up Docker containers and volumes |
| `help` | Show help message |

### Options

| Option | Description |
|--------|-------------|
| `--verbose` | Enable verbose output |
| `--fast` | Skip slow tests |
| `--focus FILE` | Run only specific test file |

### Examples

```bash
# Run tests with verbose output
./bin/test all --verbose

# Run tests excluding slow tests
./bin/test all --fast

# Run a specific test file
./bin/test all --focus spec/workers/meetings/markdown_exporter_spec.rb

# Run unit tests with verbose output
./bin/test unit --verbose
```

## Troubleshooting

### Containers won't start

If containers fail to start, try:
```bash
./bin/test clean
./bin/test setup
```

### Tests fail with database errors

The database might need to be reset:
```bash
./bin/test clean
./bin/test setup
```

### Selenium connection errors

Make sure the Selenium hub is ready:
```bash
curl http://localhost:4444/wd/hub/status
```

### Permission errors

The script might need execute permissions:
    ```bash
    chmod +x plugins/openproject-meeting-markdown-export/bin/test
    ```


## Architecture

For detailed architecture information, see the TDD plan:
- [TDD Plan](./plans/meeting-markdown-export-tdd-plan.md)

## Test Structure

```
spec/
├── workers/
│   └── meetings/
│       ├── markdown_exporter_spec.rb    # Unit tests for exporter
│       └── markdown_export_job_spec.rb   # Unit tests for job
├── models/
│   └── meeting_markdown_export_spec.rb  # Unit tests for model
├── lib/
│   └── open_project/
│       └── meeting_markdown_export/
│           └── engine_spec.rb            # Integration tests
├── requests/
│   └── meetings_markdown_export_spec.rb # Integration tests
├── features/
│   └── structured_meetings/
│       └── markdown_export_spec.rb      # Feature tests
└── components/
    └── meetings/
        └── exports/
            └── markdown_modal_dialog_component_spec.rb  # Component tests
```

## Development Workflow

Follow the TDD cycle:

1. **Write a failing test**
2. **Run the test** to confirm it fails
3. **Implement the code** to make the test pass
4. **Run the test** to confirm it passes
5. **Refactor** if needed
6. **Repeat**

Example:
```bash
# 1. Write test in spec/workers/meetings/markdown_exporter_spec.rb

# 2. Run the test
./bin/test unit --focus spec/workers/meetings/markdown_exporter_spec.rb

# 3. Implement code in app/workers/meetings/markdown_exporter.rb

# 4. Run the test again
./bin/test unit --focus spec/workers/meetings/markdown_exporter_spec.rb

# 5. Refactor and run all tests
./bin/test all
```

## Contributing

When contributing to this plugin:

1. Follow the TDD approach
2. Ensure all tests pass before submitting
3. Add tests for new features
4. Update documentation as needed
5. Follow OpenProject coding standards

## License

This plugin follows the same license as OpenProject (GPL v3).
