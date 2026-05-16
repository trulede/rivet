# Rivet

Rivet - Minimal Task.

## Usage

Rivet is built specifically for advanced workflows and minimalist environments. Unlike the upstream [Task][task-url] project, it strips out non-essential overhead to focus strictly on performance and reliable task execution.

For extensive documentation or community-driven support, please refer to the upstream [Task project][task-url].

## Development

All build and testing routines are managed via standard automation commands. Binaries are compiled to be 100% statically linked with zero dependencies on system host libraries.

```bash
# Setup a development environment.
$ make deps

# Build Rivet.
$ make build
$ make install

# Release build (all supported platforms).
$ make release

# Development commands.
$ make test
$ make test-all
$ make lint

# Other make commands:
$ make help
```

## License

This project is licensed under the MIT License. 

* Copyright (c) 2026 Timothy Rule (Modifications and current project)
* Copyright (c) 2016 Andrey Nering (Original base project)

See the [LICENSE](LICENSE) file for the full license text.


[task-url]: https://taskfile.dev
[license-url]: LICENSE
